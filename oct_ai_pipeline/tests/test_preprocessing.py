import unittest
import numpy as np
import cv2
from pathlib import Path
from oct_ai_pipeline.preprocessing.preprocessing_service import PreprocessingService

class TestPreprocessing(unittest.TestCase):
    def setUp(self):
        # Create a dummy RGB image
        self.test_img = np.random.randint(0, 255, (100, 100, 3), dtype=np.uint8)
        self.temp_path = Path("temp_test_img.png")
        cv2.imwrite(str(self.temp_path), self.test_img)

    def tearDown(self):
        if self.temp_path.exists():
            self.temp_path.unlink()

    def test_load_image(self):
        img = PreprocessingService.load_image(self.temp_path)
        self.assertEqual(img.shape, (100, 100, 3))

    def test_to_grayscale(self):
        gray = PreprocessingService.to_grayscale(self.test_img)
        self.assertEqual(len(gray.shape), 2)
        self.assertEqual(gray.shape, (100, 100))

    def test_normalize_image(self):
        img = np.array([[10, 20], [30, 40]], dtype=np.uint8)
        norm = PreprocessingService.normalize_image(img)
        self.assertEqual(np.min(norm), 0)
        self.assertEqual(np.max(norm), 255)

    def test_resize_for_model(self):
        img = np.zeros((100, 100), dtype=np.uint8)
        resized = PreprocessingService.resize_for_model(img, (512, 512))
        self.assertEqual(resized.shape, (512, 512))

    def test_preprocess_pipeline_flow(self):
        model_input, normalized, metrics = PreprocessingService.preprocess_oct(self.temp_path, (512, 512))
        self.assertEqual(model_input.shape, (512, 512))
        self.assertIn("original_size", metrics)
        self.assertEqual(metrics["target_size"], (512, 512))

if __name__ == "__main__":
    unittest.main()
