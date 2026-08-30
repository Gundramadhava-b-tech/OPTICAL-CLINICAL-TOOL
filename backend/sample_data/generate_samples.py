import cv2
import numpy as np
from pathlib import Path

def generate_realistic_retinal_oct(filename: str, has_fovea: bool = True, noise_level: float = 18.0) -> str:
    """
    Synthesizes an anatomically structured Retinal OCT B-scan:
    - Vitreous dark chamber
    - Curved ILM with foveal pit
    - Stratified retinal layers (RNFL, GCL, IPL, INL, OPL, ONL, IS/OS junction, RPE)
    - Choroidal vascular spaces & scleral attenuation
    - Rayleigh/speckle noise characteristic of coherent light interferometry
    """
    out_dir = Path(__file__).resolve().parent / "sample_scans"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / filename
    
    w, h = 768, 496
    oct_img = np.full((h, w), 22, dtype=np.float32)  # Low-intensity vitreous background
    
    # Generate Foveal / Retinal Contour
    x = np.linspace(-3.0, 3.0, w)
    
    if has_fovea:
        # Foveal pit Gaussian depression in central macula
        fovea_depth = 42.0
        fovea_width = 0.8
        foveal_pit = fovea_depth * np.exp(- (x ** 2) / (2 * (fovea_width ** 2)))
        retina_center_y = 150.0 + 15.0 * np.sin(x * 0.7) + foveal_pit
    else:
        retina_center_y = 175.0 + 12.0 * np.sin(x * 0.7)
        
    # Layer definitions with relative thickness & optical reflectivity (intensity)
    # Layer: (name, fractional_thickness, intensity_base, speckle_gain)
    layers_profile = [
        ("ILM_RNFL", 24, 185.0, 25.0),    # Highly reflective surface
        ("GCL", 20, 110.0, 15.0),         # Hyporeflective
        ("IPL", 22, 140.0, 18.0),         # Moderately reflective
        ("INL", 20, 90.0, 14.0),          # Hyporeflective dark band
        ("OPL", 22, 145.0, 18.0),         # Moderately reflective
        ("ONL", 32, 75.0, 12.0),          # Hyporeflective thick band
        ("ELM_IS", 16, 130.0, 16.0),      # Intermediate band
        ("RPE", 26, 230.0, 30.0),         # Very bright hyper-reflective band
        ("Choroid", 90, 85.0, 35.0)       # Choroidal backscatter with large vessels
    ]
    
    for col in range(w):
        current_y = retina_center_y[col]
        
        # If fovea, RNFL/GCL/IPL thin out in the center
        fovea_attenuation = 1.0 - (0.65 * np.exp(- (x[col] ** 2) / 0.5)) if has_fovea else 1.0
        
        for name, thick, intensity, speckle in layers_profile:
            actual_thick = thick * (fovea_attenuation if name in ["ILM_RNFL", "GCL", "IPL", "INL"] else 1.0)
            y_start = int(current_y)
            y_end = int(current_y + actual_thick)
            
            y_start = max(0, min(y_start, h))
            y_end = max(0, min(y_end, h))
            
            if y_end > y_start:
                # Add layer reflectivity
                oct_img[y_start:y_end, col] = intensity
                
            current_y += actual_thick

    # Add realistic OCT Optical Speckle Noise (Rayleigh / Gamma distributed)
    speckle_noise = np.random.gamma(shape=2.5, scale=noise_level / 2.5, size=(h, w))
    oct_with_speckle = oct_img + speckle_noise - (noise_level * 0.8)
    
    # Slight horizontal smoothing to simulate optical coherence scan lines
    oct_final = cv2.GaussianBlur(oct_with_speckle.astype(np.float32), (3, 1), 0)
    
    # Clip to valid 8-bit range [0, 255]
    oct_final_8u = np.clip(oct_final, 0, 255).astype(np.uint8)
    
    cv2.imwrite(str(out_path), oct_final_8u)
    return str(out_path)

def generate_non_oct_image(filename: str) -> str:
    """Generates a non-OCT photo/document image to test strict validation rejection."""
    out_dir = Path(__file__).resolve().parent / "sample_scans"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / filename
    
    img = np.ones((400, 500, 3), dtype=np.uint8) * 240
    # Colorful geometric shapes & text
    cv2.rectangle(img, (50, 50), (450, 150), (20, 120, 240), -1)
    cv2.putText(img, "STANDARD DOCUMENT / PHOTO", (70, 110), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
    cv2.circle(img, (250, 280), 80, (50, 200, 50), -1)
    cv2.imwrite(str(out_path), img)
    return str(out_path)

if __name__ == "__main__":
    p1 = generate_realistic_retinal_oct("sample_normal_macula_od.png", has_fovea=True)
    p2 = generate_realistic_retinal_oct("sample_macular_scan_os.png", has_fovea=False)
    p3 = generate_realistic_retinal_oct("sample_retinal_scan_03.png", has_fovea=True, noise_level=24.0)
    p4 = generate_non_oct_image("sample_invalid_document.png")
    print("Generated sample scans:")
    print("1:", p1)
    print("2:", p2)
    print("3:", p3)
    print("4 (Invalid):", p4)
