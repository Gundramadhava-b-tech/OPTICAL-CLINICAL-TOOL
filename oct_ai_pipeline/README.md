# OCT AI Pipeline - Isolated Testing Module

This module provides an isolated environment for testing the Optical Coherence Tomography (OCT) preprocessing and retinal layer segmentation pipeline.

## Purpose
Automated retinal layer segmentation using a Deep Learning U-Net architecture.

## Pipeline Architecture
1. **Input**: Raw OCT B-Scan (PNG, JPG, TIFF)
2. **Grayscale Standardization**: Conversion to single-channel luminance.
3. **Bilateral Filtering**: Edge-preserving speckle noise reduction.
4. **CLAHE**: Contrast Limited Adaptive Histogram Equalization.
5. **Min-Max Normalization**: Dynamic range scaling to [0-255].
6. **Resampling**: Resize to 512x512 model input dimensions.
7. **U-Net Inference**: Deep neural network segmentation (9 classes).
8. **Post-processing**: Morphological cleaning and contour extraction.
9. **Measurements**: Quantitative thickness and area extraction.
10. **Visualization**: Generation of color masks and overlays.

## Folder Structure
- `input/`: Place your OCT images here for testing.
- `output/`: Results will be saved here in timestamped subdirectories.
- `models/`: Place your trained U-Net model (`retina_unet_v1.h5`) here.
- `preprocessing/`: Image enhancement services.
- `segmentation/`: Model architecture, inference, and post-processing.
- `measurements/`: Quantitative clinical metric extraction.
- `visualization/`: Multi-layer overlay generation.

## Installation
It is recommended to use a virtual environment.

```bash
cd oct_ai_pipeline
python -m venv .venv

# Windows
.venv\Scripts\activate
# Linux/macOS
source .venv/bin/activate

pip install -r requirements.txt
```

## Running the Pipeline
Place an OCT image in `input/` and run:

```bash
python run_pipeline.py --input input/your_image.png
```

Optional: specify an output name:
```bash
python run_pipeline.py --input input/test.png --output pilot_test_01
```

## Model Placement
The pipeline expects a trained TensorFlow/Keras model at:
`oct_ai_pipeline/models/retina_unet_v1.h5`

If no model is found, the pipeline will complete the preprocessing steps and report the missing model for the segmentation stage.

## Testing
Run unit tests to verify individual components:
```bash
python -m unittest discover tests
```

## Limitations & Disclaimer
- **AI Confidence**: Summary confidence scores are derived from model softmax probabilities.
- **Accuracy**: Performance depends heavily on the training dataset and image quality.
- **Clinical Use**: This module is for research/experimental purposes and is not a certified diagnostic tool.
- **Calibration**: Default axial calibration is 3.87 µm/pixel (Standard). Always verify calibration for specific OCT hardware.
