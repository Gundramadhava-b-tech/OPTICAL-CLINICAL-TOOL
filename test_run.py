import os
import sys
from pathlib import Path

# Add project root to sys.path
root_dir = Path(__file__).resolve().parent
sys.path.append(str(root_dir))

from backend.services.segmentation_service import segmentation_service
from backend.services.preprocessing_service import OCTPreprocessingService
from backend.config import UPLOADS_DIR, PROCESSED_DIR, settings

def test_segmentation():
    print("Initializing Segmentation Service...")

    sample_image = root_dir / "backend" / "sample_data" / "sample_scans" / "sample_macular_scan_os.png"

    if not sample_image.exists():
        print(f"Sample image not found at {sample_image}")
        return

    print(f"Processing image: {sample_image.name}")

    # 1. Preprocess
    try:
        out_filename = f"preproc_test_{sample_image.name}"
        prep_output = OCTPreprocessingService.preprocess_oct_scan(
            input_file_path=sample_image,
            output_filename=out_filename,
            target_size=settings.INPUT_SIZE
        )
        processed_path = prep_output["preprocessed_file_path"]
        print(f"Preprocessed image saved to: {processed_path}")

        # 2. Segment
        results = segmentation_service.segment(processed_path, sample_image)

        print("\n--- Segmentation Results ---")
        print(f"Status: {results['status']}")
        print(f"Overall Quality: {results['overall_quality']}")
        print(f"Confidence Score: {results['confidence_score']}")
        print(f"Execution Time: {results['execution_time_ms']} ms")
        print(f"Layers Detected: {len([l for l in results['layers'] if l['is_detected']])}")

        for layer in results['layers']:
            if layer['is_detected']:
                print(f" - {layer['layer_name']}: Mean Thickness {layer['mean_thickness_um']} um (Conf: {layer['confidence_score']})")

        print(f"\nMask saved to: {results['mask_file_path']}")
        print(f"Overlay saved to: {results['overlay_file_path']}")

    except Exception as e:
        print(f"Error during processing: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_segmentation()
