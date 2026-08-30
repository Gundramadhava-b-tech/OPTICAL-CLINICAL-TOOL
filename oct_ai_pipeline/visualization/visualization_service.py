import cv2
import numpy as np
from ..config import LAYER_CLASSES, LAYER_COLORS

class VisualizationService:
    @staticmethod
    def generate_color_mask(mask: np.ndarray) -> np.ndarray:
        """Generates an RGB color-coded mask from the class map."""
        h, w = mask.shape
        color_mask = np.zeros((h, w, 3), dtype=np.uint8)

        for idx, name in enumerate(LAYER_CLASSES):
            if idx == 0: continue # Background

            if name in LAYER_COLORS:
                r, g, b, _ = LAYER_COLORS[name]
                color_mask[mask == idx] = [b, g, r] # OpenCV BGR

        return color_mask

    @staticmethod
    def generate_overlay(original_image: np.ndarray, color_mask: np.ndarray, alpha=0.55) -> np.ndarray:
        """Combines original image with color mask (55% mask, 45% image)."""
        # Ensure original is BGR
        if len(original_image.shape) == 2:
            base = cv2.cvtColor(original_image, cv2.COLOR_GRAY2BGR)
        else:
            base = original_image.copy()

        # Resize mask to base if needed
        if base.shape[:2] != color_mask.shape[:2]:
            color_mask = cv2.resize(color_mask, (base.shape[1], base.shape[0]), interpolation=cv2.INTER_NEAREST)

        # 45% base (1 - alpha) + 55% mask (alpha)
        overlay = cv2.addWeighted(base, 1 - alpha, color_mask, alpha, 0)

        # Only apply color where mask is non-zero
        mask_2d = np.any(color_mask > 0, axis=-1)
        result = base.copy()
        result[mask_2d] = overlay[mask_2d]

        return result

    @staticmethod
    def draw_layer_boundaries(image: np.ndarray, mask: np.ndarray) -> np.ndarray:
        """Draws clean contour boundaries for each detected layer."""
        if len(image.shape) == 2:
            canvas = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
        else:
            canvas = image.copy()

        for idx, name in enumerate(LAYER_CLASSES):
            if idx == 0: continue

            layer_mask = (mask == idx).astype(np.uint8) * 255
            contours, _ = cv2.findContours(layer_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

            if name in LAYER_COLORS:
                r, g, b, _ = LAYER_COLORS[name]
                cv2.drawContours(canvas, contours, -1, (b, g, r), 1, cv2.LINE_AA)

        return canvas
