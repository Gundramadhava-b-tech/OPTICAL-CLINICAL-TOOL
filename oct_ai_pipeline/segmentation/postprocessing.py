import cv2
import numpy as np
from skimage import morphology

class PostProcessingService:
    @staticmethod
    def remove_small_regions(mask: np.ndarray, min_size=500) -> np.ndarray:
        """Removes small isolated connected components from the binary masks."""
        processed_mask = np.zeros_like(mask)
        num_classes = np.max(mask) + 1

        for class_idx in range(1, num_classes):
            binary_mask = (mask == class_idx)
            # Remove objects smaller than min_size
            cleaned = morphology.remove_small_objects(binary_mask, min_size=min_size)
            processed_mask[cleaned] = class_idx

        return processed_mask

    @staticmethod
    def fill_holes(mask: np.ndarray, area_threshold=500) -> np.ndarray:
        """Fills small holes within the segmented regions."""
        processed_mask = np.zeros_like(mask)
        num_classes = np.max(mask) + 1

        for class_idx in range(1, num_classes):
            binary_mask = (mask == class_idx)
            # Fill holes
            filled = morphology.remove_small_holes(binary_mask, area_threshold=area_threshold)
            processed_mask[filled] = class_idx

        return processed_mask

    @staticmethod
    def extract_layer_contours(mask: np.ndarray, class_idx: int) -> list:
        """Extracts contours for a specific layer using OpenCV."""
        binary_mask = (mask == class_idx).astype(np.uint8) * 255
        contours, _ = cv2.findContours(binary_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        return contours

    @classmethod
    def apply_postprocessing(cls, mask: np.ndarray) -> np.ndarray:
        """Runs the post-processing pipeline on the segmentation mask."""
        # Note: skimage.morphology functions expect boolean inputs
        cleaned = cls.remove_small_regions(mask)
        filled = cls.fill_holes(cleaned)
        return filled
