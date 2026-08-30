import unittest
import numpy as np
from ..measurements.measurement_service import MeasurementService

class TestMeasurements(unittest.TestCase):
    def test_calculate_layer_metrics(self):
        # Create a mask with a 10-pixel thick layer of class 1 (ILM)
        mask = np.zeros((100, 100), dtype=np.uint8)
        mask[10:20, :] = 1

        metrics = MeasurementService.calculate_layer_metrics(mask, 1, "ILM", 3.87)

        self.assertTrue(metrics["detected"])
        self.assertEqual(metrics["thickness_px"]["mean"], 10.0)
        self.assertEqual(metrics["thickness_px"]["min"], 10.0)
        self.assertEqual(metrics["thickness_px"]["max"], 10.0)
        self.assertAlmostEqual(metrics["thickness_um"]["mean"], 38.7, places=2)

    def test_empty_layer(self):
        mask = np.zeros((100, 100), dtype=np.uint8)
        metrics = MeasurementService.calculate_layer_metrics(mask, 1, "ILM", 3.87)
        self.assertFalse(metrics["detected"])
        self.assertEqual(metrics["area_px"], 0)

if __name__ == "__main__":
    unittest.main()
