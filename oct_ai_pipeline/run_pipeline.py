import os
import sys
import json
import argparse
import time
import cv2
import numpy as np
from datetime import datetime
from pathlib import Path

# Add pipeline root to path
sys.path.append(str(Path(__file__).resolve().parent))

from config import (
    INPUT_HEIGHT, INPUT_WIDTH, NUM_CLASSES, MODEL_PATH,
    OUTPUT_DIR, AXIAL_CALIBRATION_UM_PER_PIXEL
)
from preprocessing.preprocessing_service import PreprocessingService
from segmentation.segmentation_service import SegmentationService
from measurements.measurement_service import MeasurementService
from visualization.visualization_service import VisualizationService

def run_pipeline(input_path: str, output_subdir: str = None):
    print(f"\n--- OCT AI Pipeline Run: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ---")

    input_file = Path(input_path)
    if not input_file.exists():
        print(f"Error: Input file {input_path} not found.")
        return

    # 1. Create output directory
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    if output_subdir:
        run_output_dir = OUTPUT_DIR / output_subdir
    else:
        run_output_dir = OUTPUT_DIR / f"run_{timestamp}"
    run_output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Input: {input_file.name}")
    print(f"Output Directory: {run_output_dir}")

    # 2. Preprocessing
    print("\n[1/6] Running Preprocessing...")
    try:
        model_ready_img, full_res_gray, prep_metrics = PreprocessingService.preprocess_oct(
            input_file, (INPUT_WIDTH, INPUT_HEIGHT)
        )
        cv2.imwrite(str(run_output_dir / "preprocessed.png"), model_ready_img)
        print(" - Preprocessing completed.")
    except Exception as e:
        print(f"Error during preprocessing: {e}")
        return

    # 3. Segmentation
    print("\n[2/6] Loading U-Net Model...")
    seg_service = SegmentationService(MODEL_PATH, NUM_CLASSES, (INPUT_HEIGHT, INPUT_WIDTH, 1))
    try:
        seg_service.load_model()
    except FileNotFoundError as fnf:
        print(f"\nCRITICAL: {fnf}")
        print("Note: Preprocessing results saved. Pipeline stopping due to missing model.")
        return
    except Exception as e:
        print(f"Error loading model: {e}")
        return

    print("\n[3/6] Running AI Segmentation...")
    start_time = time.time()
    seg_results = seg_service.segment_oct(model_ready_img)
    exec_time = round((time.time() - start_time) * 1000, 2)

    mask = seg_results["mask"]
    print(f" - Segmentation completed in {exec_time} ms.")
    print(f" - AI Confidence: {round(seg_results.get('confidence', 0) * 100, 1)}%")

    # 4. Measurements
    print("\n[4/6] Extracting Quantitative Measurements...")
    measurements = MeasurementService.extract_all_measurements(mask, AXIAL_CALIBRATION_UM_PER_PIXEL)
    print(f" - Measurements extracted for {len([m for m in measurements.values() if m['detected']])} layers.")

    # 5. Visualization
    print("\n[5/6] Generating Visualizations...")
    color_mask = VisualizationService.generate_color_mask(mask)
    overlay = VisualizationService.generate_overlay(model_ready_img, color_mask)
    boundaries = VisualizationService.draw_layer_boundaries(model_ready_img, mask)

    cv2.imwrite(str(run_output_dir / "segmentation_mask.png"), color_mask)
    cv2.imwrite(str(run_output_dir / "overlay.png"), overlay)
    cv2.imwrite(str(run_output_dir / "layer_boundaries.png"), boundaries)
    # Save original grayscale as reference
    cv2.imwrite(str(run_output_dir / "original_gray.png"), full_res_gray)
    print(" - Visualizations saved.")

    # 6. Save Analysis JSON
    print("\n[6/6] Finalizing Analysis Report...")
    analysis_data = {
        "input_file": input_file.name,
        "run_timestamp": timestamp,
        "image_size": prep_metrics["original_size"],
        "model_input_size": [INPUT_WIDTH, INPUT_HEIGHT],
        "preprocessing": prep_metrics,
        "model": {
            "architecture": "U-Net 4-Depth Residual",
            "classes": NUM_CLASSES,
            "weights": MODEL_PATH.name
        },
        "performance": {
            "execution_time_ms": exec_time,
            "ai_confidence": seg_results.get("confidence")
        },
        "measurements": measurements,
        "calibration": {
            "axial_um_per_pixel": AXIAL_CALIBRATION_UM_PER_PIXEL,
            "unit": "micrometers (μm)"
        }
    }

    with open(run_output_dir / "analysis.json", "w") as f:
        json.dump(analysis_data, f, indent=2)

    print(f"\nSUCCESS: Analysis complete. Results saved in {run_output_dir}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="RetinaSeg OCT AI Pipeline CLI")
    parser.add_argument("--input", type=str, required=True, help="Path to input OCT image")
    parser.add_argument("--output", type=str, help="Subdirectory name for output")

    args = parser.parse_args()
    run_pipeline(args.input, args.output)
