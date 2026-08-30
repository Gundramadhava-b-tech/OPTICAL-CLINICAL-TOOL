# OCT Image Processing & Model Training

This sub-module is dedicated to the experimental training of deep learning models for retinal layer segmentation and pathology detection (e.g., Macular Edema, Cysts).

## 📂 Structure
- `dataset/images/`: Input OCT B-scans (standardized grayscale).
- `dataset/masks/`: Ground truth segmentation masks (one-hot encoded).
- `checkpoints/`: Saved model weights (`best_model.h5`).
- `logs/`: Training metrics and CSV logs.
- `train_model.py`: Main training script using TensorFlow and the U-Net architecture.

## 🔬 Training Focus: Intraretinal Fluid (Cysts)
The reference image provided demonstrates a retina with significant cystic spaces (Intraretinal Fluid). The training pipeline is configured to recognize these microstructural irregularities by:
1. Standardizing optical luminance.
2. Applying bilateral noise suppression.
3. Training a 4-depth U-Net to delineate layer boundaries even when displaced by fluid.

## 🚀 How to Train
1. Ensure dependencies from `oct_ai_pipeline/requirements.txt` are installed.
2. Place expert-annotated masks in `dataset/masks/` (matching filenames in `dataset/images/`).
3. Run the training script:
   ```bash
   python train_model.py
   ```

## ⚠️ Notes
- For demonstration, the script generates 'mock' masks if the folder is empty.
- High-fidelity clinical results require at least 500+ expert-annotated B-scans.
