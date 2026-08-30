import numpy as np
from ..config import LAYER_CLASSES, AXIAL_CALIBRATION_UM_PER_PIXEL

class MeasurementService:
    @staticmethod
    def calculate_layer_metrics(mask: np.ndarray, class_idx: int, layer_name: str, axial_calibration: float = None) -> dict:
        """Calculates thickness metrics and area for a specific retinal layer."""
        layer_mask = (mask == class_idx)

        # Area in pixels
        area_px = int(np.sum(layer_mask))

        if area_px == 0:
            return {
                "layer_name": layer_name,
                "detected": False,
                "area_px": 0,
                "thickness_px": {"mean": 0, "min": 0, "max": 0}
            }

        # Calculate thickness per column (A-scan)
        # Sum non-zero pixels vertically for each column
        column_thicknesses = np.sum(layer_mask, axis=0)
        # Only consider columns where the layer exists
        active_columns = column_thicknesses[column_thicknesses > 0]

        metrics_px = {
            "mean": float(np.mean(active_columns)),
            "min": float(np.min(active_columns)),
            "max": float(np.max(active_columns))
        }

        result = {
            "layer_name": layer_name,
            "detected": True,
            "area_px": area_px,
            "thickness_px": metrics_px
        }

        # Apply axial calibration if available
        if axial_calibration:
            result["thickness_um"] = {
                "mean": round(metrics_px["mean"] * axial_calibration, 2),
                "min": round(metrics_px["min"] * axial_calibration, 2),
                "max": round(metrics_px["max"] * axial_calibration, 2),
                "calibration_value": axial_calibration
            }

        return result

    @classmethod
    def extract_all_measurements(cls, mask: np.ndarray, axial_calibration: float = AXIAL_CALIBRATION_UM_PER_PIXEL) -> dict:
        """Extracts measurements for all defined retinal layers."""
        measurements = {}

        for idx, name in enumerate(LAYER_CLASSES):
            if idx == 0: continue # Skip background

            measurements[name] = cls.calculate_layer_metrics(mask, idx, name, axial_calibration)

        return measurements
