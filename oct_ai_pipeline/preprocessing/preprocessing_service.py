import cv2
import numpy as np
from pathlib import Path
from PIL import Image

class PreprocessingService:
    @staticmethod
    def load_image(image_path: str | Path) -> np.ndarray:
        """Loads an image using OpenCV."""
        path = str(image_path)
        img = cv2.imread(path)
        if img is None:
            raise ValueError(f"Could not load image at {image_path}")
        return img

    @staticmethod
    def to_grayscale(image: np.ndarray) -> np.ndarray:
        """Converts image to single-channel grayscale if it's RGB."""
        if len(image.shape) == 3:
            return cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        return image.copy()

    @staticmethod
    def apply_bilateral_filter(image: np.ndarray, d=9, sigma_color=75, sigma_space=75) -> np.ndarray:
        """Applies bilateral filtering to reduce noise while preserving boundaries."""
        return cv2.bilateralFilter(image, d, sigma_color, sigma_space)

    @staticmethod
    def apply_clahe(image: np.ndarray, clip_limit=2.5, tile_grid_size=(8, 8)) -> np.ndarray:
        """Applies Contrast Limited Adaptive Histogram Equalization."""
        clahe = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=tile_grid_size)
        return clahe.apply(image)

    @staticmethod
    def normalize_image(image: np.ndarray) -> np.ndarray:
        """Min-max normalization to 0-255 range."""
        img_float = image.astype(float)
        i_min = np.min(img_float)
        i_max = np.max(img_float)

        if i_max == i_min:
            return np.zeros(image.shape, dtype=np.uint8)

        norm = ((img_float - i_min) / (i_max - i_min)) * 255.0
        return norm.astype(np.uint8)

    @staticmethod
    def resize_for_model(image: np.ndarray, target_size=(512, 512)) -> np.ndarray:
        """Resizes image using area interpolation for downsampling."""
        return cv2.resize(image, target_size, interpolation=cv2.INTER_AREA)

    @classmethod
    def preprocess_oct(cls, image_path: str | Path, target_size=(512, 512)) -> tuple[np.ndarray, np.ndarray, dict]:
        """Runs the complete OCT preprocessing pipeline."""
        orig_img = cls.load_image(image_path)
        gray = cls.to_grayscale(orig_img)
        filtered = cls.apply_bilateral_filter(gray)
        clahe = cls.apply_clahe(filtered)
        normalized = cls.normalize_image(clahe)
        model_input = cls.resize_for_model(normalized, target_size)

        metrics = {
            "original_size": [orig_img.shape[1], orig_img.shape[0]],
            "normalization": "min-max",
            "bilateral": {"d": 9, "sigma_color": 75, "sigma_space": 75},
            "clahe": {"clip_limit": 2.5, "tile_grid": [8, 8]},
            "target_size": target_size
        }

        return model_input, normalized, metrics
