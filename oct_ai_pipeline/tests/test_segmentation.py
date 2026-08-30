import unittest
import numpy as np
from pathlib import Path
from ..segmentation.segmentation_service import SegmentationService
from ..segmentation.unet_model import build_unet

class TestSegmentation(unittest.TestCase):
    def setUp(self):
        self.model_path = Path("non_existent_model.h5")
        self.service = SegmentationService(self.model_path)

    def test_prepare_tensor(self):
        img = np.random.randint(0, 255, (512, 512), dtype=np.uint8)
        tensor = self.service.prepare_tensor(img)
        self.assertEqual(tensor.shape, (1, 512, 512, 1))
        self.assertEqual(tensor.dtype, np.float32)
        self.assertTrue(np.max(tensor) <= 1.0)

    def test_decode_segmentation(self):
        # Create a mock softmax output (1, 2, 2, 9)
        mock_pred = np.zeros((1, 2, 2, 9), dtype=np.float32)
        # Class 1 at (0,0), Class 8 at (1,1)
        mock_pred[0, 0, 0, 1] = 0.9
        mock_pred[0, 1, 1, 8] = 0.8
        # Background elsewhere
        mock_pred[0, 0, 1, 0] = 1.0
        mock_pred[0, 1, 0, 0] = 1.0

        mask, conf = self.service.decode_segmentation(mock_pred)

        self.assertEqual(mask[0, 0], 1)
        self.assertEqual(mask[1, 1], 8)
        self.assertEqual(mask[0, 1], 0)
        self.assertAlmostEqual(conf, 0.85, places=2) # Mean of 0.9 and 0.8

if __name__ == "__main__":
    unittest.main()
