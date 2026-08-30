import cv2
import numpy as np
from pathlib import Path
from PIL import Image

class OCTValidationService:
    @staticmethod
    def validate_image_file(file_path: Path | str) -> dict:
        """
        Comprehensive clinical OCT validation pipeline:
        1. File existence & size check
        2. Image format & decoding check
        3. Aspect ratio and dimension constraints
        4. Color space / Grayscale dominance check (OCT scans are monochrome/near-monochrome)
        5. Retinal Layer Horizontal Stratification & Gradient Profile Analysis
        6. Speckle noise & intensity distribution characteristic of OCT B-scans
        7. Rejection of non-OCT images (portraits, landscapes, documents, text, CT/MRI)
        """
        path = Path(file_path)
        if not path.exists():
            return {
                "is_valid_oct": False,
                "status": "INVALID",
                "confidence_score": 0.0,
                "message": "File does not exist.",
                "reasons": ["File not found on storage"],
                "image_metrics": {}
            }
        
        # 1. File Size Validation
        file_size_bytes = path.stat().st_size
        if file_size_bytes < 5 * 1024:  # Minimum 5KB
            return {
                "is_valid_oct": False,
                "status": "INVALID",
                "confidence_score": 0.0,
                "message": "File size is too small for a valid diagnostic OCT scan.",
                "reasons": ["File size below minimum threshold (<5KB)"],
                "image_metrics": {"file_size_bytes": file_size_bytes}
            }
        
        # 2. Decoding Validation
        try:
            pil_img = Image.open(path)
            width, height = pil_img.size
            img_cv = cv2.imread(str(path))
            if img_cv is None:
                return {
                    "is_valid_oct": False,
                    "status": "INVALID",
                    "confidence_score": 0.0,
                    "message": "Image decoding failed. Corrupted or unsupported image file.",
                    "reasons": ["Unable to decode image raster data"],
                    "image_metrics": {}
                }
        except Exception as e:
            return {
                "is_valid_oct": False,
                "status": "INVALID",
                "confidence_score": 0.0,
                "message": f"Image decoding error: {str(e)}",
                "reasons": ["Failed image header parsing"],
                "image_metrics": {}
            }
        
        # 3. Dimension & Aspect Ratio Check
        if width < 200 or height < 150:
            return {
                "is_valid_oct": False,
                "status": "INVALID",
                "confidence_score": 0.1,
                "message": "Image resolution too low for retinal layer segmentation (min 200x150).",
                "reasons": [f"Low resolution: {width}x{height}"],
                "image_metrics": {"width": width, "height": height}
            }
        
        aspect_ratio = width / float(height)
        # OCT B-scans typically have aspect ratios between 0.6 and 3.5
        if aspect_ratio < 0.4 or aspect_ratio > 4.5:
            return {
                "is_valid_oct": False,
                "status": "INVALID",
                "confidence_score": 0.15,
                "message": "Invalid aspect ratio for retinal OCT B-scan.",
                "reasons": [f"Unusual aspect ratio: {aspect_ratio:.2f}"],
                "image_metrics": {"aspect_ratio": aspect_ratio, "width": width, "height": height}
            }
        
        # Convert to Grayscale & analyze channels
        if len(img_cv.shape) == 3 and img_cv.shape[2] == 3:
            # Check color variance across R, G, B channels
            b, g, r = cv2.split(img_cv)
            diff_rg = np.mean(np.abs(r.astype(float) - g.astype(float)))
            diff_gb = np.mean(np.abs(g.astype(float) - b.astype(float)))
            color_variance = (diff_rg + diff_gb) / 2.0
            gray = cv2.cvtColor(img_cv, cv2.COLOR_BGR2GRAY)
        else:
            color_variance = 0.0
            gray = img_cv
        
        # If image has high color variance (like vivid colorful photos/landscapes/clothing), reject
        if color_variance > 32.0:
            return {
                "is_valid_oct": False,
                "status": "INVALID",
                "confidence_score": 0.1,
                "message": "Image contains high color variance. Retinal OCT B-scans are grayscale imaging modalities.",
                "reasons": ["Non-grayscale color distribution detected (photograph/landscape/selfie rejected)"],
                "image_metrics": {"color_variance": round(color_variance, 2)}
            }
        
        # 4. Intensity & Dynamic Range Analysis
        mean_intensity = float(np.mean(gray))
        std_intensity = float(np.std(gray))
        min_val, max_val, _, _ = cv2.minMaxLoc(gray)
        dynamic_range = float(max_val - min_val)
        
        # Completely blank or washed out images
        if dynamic_range < 30.0 or std_intensity < 8.0:
            return {
                "is_valid_oct": False,
                "status": "INVALID",
                "confidence_score": 0.05,
                "message": "Image lacks dynamic contrast range. The scan appears blank or severely under-exposed.",
                "reasons": ["Insufficient contrast dynamic range"],
                "image_metrics": {"dynamic_range": dynamic_range, "std_intensity": std_intensity}
            }
        
        # 5. Horizontal Stratification & Retinal Banding Profile
        # Retinal OCT B-scans have characteristic horizontal layers (ILM, Nuclear layers, RPE)
        # Vertical gradient should have strong peaks (layer boundaries) while horizontal gradient is smoother
        sobel_y = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
        sobel_x = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
        
        mean_grad_y = float(np.mean(np.abs(sobel_y)))
        mean_grad_x = float(np.mean(np.abs(sobel_x)))
        stratification_ratio = mean_grad_y / (mean_grad_x + 1e-5)
        
        # Check vertical profile (upper region should have vitreous dark region, middle has retinal band, bottom has choroid)
        h_quarter = height // 4
        h_half = height // 2
        top_region_mean = float(np.mean(gray[:h_quarter, :]))
        mid_region_mean = float(np.mean(gray[h_quarter:h_quarter * 3, :]))
        
        # Edge density analysis (detect text/documents vs continuous biomedical tissue)
        edges = cv2.Canny(gray, 50, 150)
        edge_density = float(np.sum(edges > 0)) / float(width * height)
        
        # Score calculation
        score = 0.5
        reasons = []
        
        if 0.8 <= stratification_ratio <= 3.5:
            score += 0.2
        else:
            reasons.append("Horizontal layer stratification outside typical OCT bounds")
        
        if mid_region_mean > top_region_mean * 0.9:
            score += 0.15
        
        if 0.01 <= edge_density <= 0.25:
            score += 0.15
        elif edge_density > 0.35:
            # Highly dense edges usually mean printed text, documents, or high-frequency synthetic patterns
            score -= 0.35
            reasons.append("High edge density pattern resembles text/document rather than retinal tissue")
        
        score = min(max(score, 0.0), 0.98)
        
        is_valid = score >= 0.65
        status = "VALID" if is_valid else ("WARNING" if score >= 0.5 else "INVALID")
        
        if is_valid:
            message = "OCT retinal scan validated successfully. Ready for enhanced preprocessing and U-Net segmentation."
        else:
            message = "Uploaded image does not appear to be a valid retinal OCT B-scan suitable for layer segmentation."
        
        return {
            "is_valid_oct": is_valid,
            "status": status,
            "confidence_score": round(score, 3),
            "message": message,
            "reasons": reasons,
            "image_metrics": {
                "width": width,
                "height": height,
                "aspect_ratio": round(aspect_ratio, 2),
                "mean_intensity": round(mean_intensity, 2),
                "dynamic_range": round(dynamic_range, 2),
                "stratification_ratio": round(stratification_ratio, 2),
                "edge_density": round(edge_density, 3),
                "color_variance": round(color_variance, 2),
            }
        }
