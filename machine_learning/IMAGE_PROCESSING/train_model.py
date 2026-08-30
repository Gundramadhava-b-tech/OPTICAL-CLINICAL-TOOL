import os
import cv2
import numpy as np
import tensorflow as tf
from pathlib import Path
from tensorflow.keras.callbacks import ModelCheckpoint, CSVLogger, EarlyStopping

# Importing U-Net builder from our isolated pipeline
import sys
pipeline_path = Path(__file__).resolve().parent.parent.parent / "oct_ai_pipeline"
sys.path.append(str(pipeline_path))
from segmentation.unet_model import build_unet
from preprocessing.preprocessing_service import PreprocessingService

# Configuration
DATASET_DIR = Path(__file__).resolve().parent / "dataset"
IMAGES_DIR = DATASET_DIR / "images"
MASKS_DIR = DATASET_DIR / "masks"
CHECKPOINTS_DIR = Path(__file__).resolve().parent / "checkpoints"
LOGS_DIR = Path(__file__).resolve().parent / "logs"

INPUT_SIZE = (512, 512)
BATCH_SIZE = 2
EPOCHS = 10
NUM_CLASSES = 9

def create_mock_masks():
    """Generates initial ground truth masks for training using existing algorithms."""
    print("Generating initial training masks...")
    from segmentation.segmentation_service import SegmentationService

    # We use a dummy model or existing service to create 'silver' standard masks for demonstration
    # In production, these are expert-annotated.
    for img_path in IMAGES_DIR.glob("*.png"):
        mask_path = MASKS_DIR / img_path.name
        if not mask_path.exists():
            # Load and Preprocess
            img = PreprocessingService.load_image(img_path)
            gray = PreprocessingService.to_grayscale(img)
            norm = PreprocessingService.normalize_image(gray)
            resized = PreprocessingService.resize_for_model(norm, INPUT_SIZE)

            # Simple thresholding/heuristic mask for demonstration
            # In a real training session, this would be a loaded .npy or .png mask
            mock_mask = np.zeros(INPUT_SIZE, dtype=np.uint8)
            # Just mark a band as 'retina' for class 1
            mock_mask[200:350, :] = 1

            cv2.imwrite(str(mask_path), mock_mask)
            print(f" - Created mock mask for: {img_path.name}")

class OCTDataGenerator(tf.keras.utils.Sequence):
    def __init__(self, images_dir, masks_dir, batch_size=2, input_size=(512, 512), num_classes=9):
        self.image_paths = sorted(list(images_dir.glob("*.png")))
        self.mask_paths = sorted(list(masks_dir.glob("*.png")))
        self.batch_size = batch_size
        self.input_size = input_size
        self.num_classes = num_classes

    def __len__(self):
        return int(np.ceil(len(self.image_paths) / float(self.batch_size)))

    def __getitem__(self, idx):
        batch_x = self.image_paths[idx * self.batch_size:(idx + 1) * self.batch_size]
        batch_y = self.mask_paths[idx * self.batch_size:(idx + 1) * self.batch_size]

        x = []
        y = []

        for img_p, mask_p in zip(batch_x, batch_y):
            # Load image
            img = cv2.imread(str(img_p), cv2.IMREAD_GRAYSCALE)
            img = cv2.resize(img, self.input_size)
            img = img.astype(np.float32) / 255.0
            img = np.expand_dims(img, axis=-1)
            x.append(img)

            # Load mask
            mask = cv2.imread(str(mask_p), cv2.IMREAD_GRAYSCALE)
            mask = cv2.resize(mask, self.input_size, interpolation=cv2.INTER_NEAREST)
            # Convert to one-hot
            mask_one_hot = tf.keras.utils.to_categorical(mask, num_classes=self.num_classes)
            y.append(mask_one_hot)

        return np.array(x), np.array(y)

def train():
    # 1. Setup Data
    if not MASKS_DIR.exists(): MASKS_DIR.mkdir(parents=True)
    create_mock_masks()

    gen = OCTDataGenerator(IMAGES_DIR, MASKS_DIR, BATCH_SIZE, INPUT_SIZE, NUM_CLASSES)

    if len(gen) == 0:
        print("Error: No training data found.")
        return

    # 2. Build Model
    print("\nInitializing U-Net Architecture...")
    model = build_unet(input_shape=(INPUT_SIZE[0], INPUT_SIZE[1], 1), num_classes=NUM_CLASSES)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),
        loss="categorical_crossentropy",
        metrics=["accuracy"]
    )

    # 3. Callbacks
    CHECKPOINTS_DIR.mkdir(exist_ok=True)
    LOGS_DIR.mkdir(exist_ok=True)

    callbacks = [
        ModelCheckpoint(str(CHECKPOINTS_DIR / "best_model.h5"), save_best_only=True, monitor="accuracy"),
        CSVLogger(str(LOGS_DIR / "training_log.csv")),
        EarlyStopping(monitor="accuracy", patience=5, restore_best_weights=True)
    ]

    # 4. Run Training
    print(f"\nStarting training on {len(gen.image_paths)} images...")
    print("Pathology Target: Intraretinal Fluid & Cystic Spaces (as shown in reference image)")

    model.fit(
        gen,
        epochs=EPOCHS,
        callbacks=callbacks,
        verbose=1
    )

    print("\nTraining Complete.")
    print(f"Model saved to: {CHECKPOINTS_DIR / 'best_model.h5'}")

if __name__ == "__main__":
    train()
