import unittest
import numpy as np
from pathlib import Path
import tempfile
import cv2
from PIL import Image

from backend.config import settings
from backend.services.preprocessing_service import OCTPreprocessingService
from backend.services.segmentation_service import segmentation_service
from backend.services.validation_service import OCTValidationService

class TestOCTAIPipeline(unittest.TestCase):
    """
    Comprehensive Unit Test Suite for the 16-Step OCT AI Preprocessing & U-Net Retinal Layer Segmentation Pipeline.
    """

    @classmethod
    def setUpClass(cls):
        # Create a synthetic retinal OCT B-Scan for testing
        cls.temp_dir = tempfile.TemporaryDirectory()
        cls.test_image_path = Path(cls.temp_dir.name) / "test_retina_scan.png"
        
        # Generate a realistic 512x512 OCT B-Scan pattern
        img = np.zeros((512, 512), dtype=np.uint8)
        # Background noise
        noise = np.random.normal(20, 8, (512, 512)).clip(0, 255).astype(np.uint8)
        img = cv2.add(img, noise)
        
        # Draw anatomical retinal bands (ILM to RPE)
        for y_offset, thickness, intensity in [
            (180, 8, 190),   # ILM
            (195, 20, 160),  # RNFL
            (220, 16, 130),  # GCL
            (240, 18, 145),  # IPL
            (262, 16, 110),  # INL
            (282, 14, 135),  # OPL
            (300, 30, 90),   # ONL
            (335, 18, 220),  # RPE
        ]:
            cv2.rectangle(img, (50, y_offset), (462, y_offset + thickness), int(intensity), -1)
            
        cv2.imwrite(str(cls.test_image_path), img)

    @classmethod
    def tearDownClass(cls):
        cls.temp_dir.cleanup()

    def test_01_image_loading_and_decoding(self):
        """Step 1: Verify raw OCT image loading from disk."""
        self.assertTrue(self.test_image_path.exists())
        img = cv2.imread(str(self.test_image_path))
        self.assertIsNotNone(img)
        self.assertEqual(len(img.shape), 3)

    def test_02_grayscale_conversion(self):
        """Step 2: Verify conversion to single-channel 8-bit grayscale."""
        img = cv2.imread(str(self.test_image_path))
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        self.assertEqual(len(gray.shape), 2)
        self.assertEqual(gray.dtype, np.uint8)

    def test_03_bilateral_filtering(self):
        """Step 3: Test edge-preserving bilateral filtering for speckle noise reduction."""
        gray = cv2.imread(str(self.test_image_path), cv2.IMREAD_GRAYSCALE)
        filtered = OCTPreprocessingService.apply_bilateral_filter(gray, d=9, sigma_color=75, sigma_space=75)
        self.assertEqual(filtered.shape, gray.shape)
        # Speckle variance should decrease while preserving edge contrast
        self.assertLessEqual(np.std(filtered[0:100, 0:100]), np.std(gray[0:100, 0:100]) + 1.0)

    def test_04_clahe_contrast_enhancement(self):
        """Step 4: Verify Contrast Limited Adaptive Histogram Equalization."""
        gray = cv2.imread(str(self.test_image_path), cv2.IMREAD_GRAYSCALE)
        enhanced = OCTPreprocessingService.apply_clahe(gray, clip_limit=2.5, grid_size=(8, 8))
        self.assertEqual(enhanced.shape, gray.shape)
        # Dynamic range enhancement test
        self.assertGreaterEqual(enhanced.max() - enhanced.min(), gray.max() - gray.min())

    def test_05_min_max_intensity_normalization(self):
        """Step 5: Test intensity standardisation to [0.0, 1.0]."""
        gray = cv2.imread(str(self.test_image_path), cv2.IMREAD_GRAYSCALE)
        norm = OCTPreprocessingService.normalize_intensity(gray)
        self.assertEqual(norm.dtype, np.float32)
        self.assertAlmostEqual(float(norm.min()), 0.0, places=2)
        self.assertAlmostEqual(float(norm.max()), 1.0, places=2)

    def test_06_target_resizing_512x512(self):
        """Step 6: Test standardized input resizing to 512x512 resolution."""
        non_standard = np.zeros((400, 600), dtype=np.uint8)
        resized = OCTPreprocessingService.resize_image(non_standard, target_size=(512, 512))
        self.assertEqual(resized.shape, (512, 512))

    def test_07_complete_preprocessing_pipeline(self):
        """Step 7: Verify end-to-end preprocessing execution."""
        out_name = "preprocessed_test.png"
        res = OCTPreprocessingService.preprocess_oct_scan(
            input_file_path=str(self.test_image_path),
            output_filename=out_name
        )
        self.assertTrue(Path(res["preprocessed_file_path"]).exists())
        self.assertGreater(res["execution_time_ms"], 0)
        self.assertTrue(any("CLAHE" in m for m in res["methods_applied"]))

    def test_08_tissue_validation_service(self):
        """Step 8: Verify retinal layer structure validation metrics."""
        val = OCTValidationService.validate_image_file(self.test_image_path)
        self.assertIn("is_valid_oct", val)
        self.assertIn("confidence_score", val)
        self.assertGreaterEqual(val["confidence_score"], 0.6)

    def test_09_unet_input_tensor_shape(self):
        """Step 9: Test tensor preparation formatted as [1, 1, 512, 512]."""
        gray = cv2.imread(str(self.test_image_path), cv2.IMREAD_GRAYSCALE)
        resized = cv2.resize(gray, (512, 512))
        tensor = resized.astype(np.float32) / 255.0
        tensor = np.expand_dims(np.expand_dims(tensor, axis=0), axis=0)
        self.assertEqual(tensor.shape, (1, 1, 512, 512))

    def test_10_unet_segmentation_execution(self):
        """Step 10: Verify multi-layer U-Net segmentation execution."""
        out_name = "preprocessed_unet_test.png"
        prep_res = OCTPreprocessingService.preprocess_oct_scan(
            input_file_path=str(self.test_image_path),
            output_filename=out_name
        )
        seg_res = segmentation_service.segment(
            preprocessed_image_path=prep_res["preprocessed_file_path"],
            original_image_path=str(self.test_image_path),
            confidence_threshold=0.5,
            axial_calibration_um=3.87
        )
        self.assertIn("confidence_score", seg_res)
        self.assertIn("layers", seg_res)
        self.assertGreaterEqual(len(seg_res["layers"]), 8)

    def test_11_retinal_layer_class_mapping(self):
        """Step 11: Verify exact 8-layer anatomical class indexing."""
        expected_layers = ["ILM", "RNFL", "GCL", "IPL", "INL", "OPL", "ONL", "RPE"]
        out_name = "preprocessed_classes_test.png"
        prep_res = OCTPreprocessingService.preprocess_oct_scan(
            input_file_path=str(self.test_image_path),
            output_filename=out_name
        )
        seg_res = segmentation_service.segment(
            preprocessed_image_path=prep_res["preprocessed_file_path"],
            original_image_path=str(self.test_image_path)
        )
        detected_names = [l["layer_name"] for l in seg_res["layers"]]
        for exp in expected_layers:
            self.assertIn(exp, detected_names)

    def test_12_layer_thickness_calibration_um(self):
        """Step 12: Verify axial thickness measurement calibration in micrometers."""
        out_name = "preprocessed_thick_test.png"
        prep_res = OCTPreprocessingService.preprocess_oct_scan(
            input_file_path=str(self.test_image_path),
            output_filename=out_name
        )
        seg_res = segmentation_service.segment(
            preprocessed_image_path=prep_res["preprocessed_file_path"],
            original_image_path=str(self.test_image_path),
            axial_calibration_um=3.87
        )
        for layer in seg_res["layers"]:
            if layer["is_detected"]:
                self.assertIsNotNone(layer["mean_thickness_um"])
                self.assertGreater(layer["mean_thickness_um"], 0.0)

    def test_13_layer_area_pixels_calculation(self):
        """Step 13: Test layer area calculations in square pixels."""
        out_name = "preprocessed_area_test.png"
        prep_res = OCTPreprocessingService.preprocess_oct_scan(
            input_file_path=str(self.test_image_path),
            output_filename=out_name
        )
        seg_res = segmentation_service.segment(
            preprocessed_image_path=prep_res["preprocessed_file_path"],
            original_image_path=str(self.test_image_path)
        )
        for layer in seg_res["layers"]:
            self.assertIn("layer_area_px", layer)
            self.assertGreaterEqual(layer["layer_area_px"], 0)

    def test_14_overlay_mask_generation(self):
        """Step 14: Verify color overlay generation and file persistence."""
        out_name = "preprocessed_overlay_test.png"
        prep_res = OCTPreprocessingService.preprocess_oct_scan(
            input_file_path=str(self.test_image_path),
            output_filename=out_name
        )
        seg_res = segmentation_service.segment(
            preprocessed_image_path=prep_res["preprocessed_file_path"],
            original_image_path=str(self.test_image_path)
        )
        self.assertTrue(Path(seg_res["mask_file_path"]).exists())
        self.assertTrue(Path(seg_res["overlay_file_path"]).exists())

    def test_15_findings_summary_generation(self):
        """Step 15: Verify diagnostic findings text synthesis."""
        out_name = "preprocessed_findings_test.png"
        prep_res = OCTPreprocessingService.preprocess_oct_scan(
            input_file_path=str(self.test_image_path),
            output_filename=out_name
        )
        seg_res = segmentation_service.segment(
            preprocessed_image_path=prep_res["preprocessed_file_path"],
            original_image_path=str(self.test_image_path)
        )
        self.assertIsNotNone(seg_res["findings_summary"])
        self.assertGreater(len(seg_res["findings_summary"]), 10)

    def test_16_json_export_structure(self):
        """Step 16: Verify structured JSON output adherence."""
        out_name = "preprocessed_json_test.png"
        prep_res = OCTPreprocessingService.preprocess_oct_scan(
            input_file_path=str(self.test_image_path),
            output_filename=out_name
        )
        seg_res = segmentation_service.segment(
            preprocessed_image_path=prep_res["preprocessed_file_path"],
            original_image_path=str(self.test_image_path)
        )
        self.assertIn("overall_quality", seg_res)
        self.assertIn("execution_time_ms", seg_res)
        self.assertIn("axial_calibration_um", seg_res)

if __name__ == "__main__":
    unittest.main()
