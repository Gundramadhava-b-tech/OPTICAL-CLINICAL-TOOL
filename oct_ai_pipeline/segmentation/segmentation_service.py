import os
import numpy as np
import tensorflow as tf
from pathlib import Path
from .unet_model import build_unet
from .postprocessing import PostProcessingService

class SegmentationService:
    def __init__(self, model_path: str | Path, num_classes=9, input_shape=(512, 512, 1)):
        self.model_path = Path(model_path)
        self.num_classes = num_classes
        self.input_shape = input_shape
        self.model = None

    def load_model(self):
        """Loads the trained U-Net model. Fails if not found."""
        if not self.model_path.exists():
            raise FileNotFoundError(
                f"No trained U-Net model found at {self.model_path}.\n"
                "Please place the trained model inside the models/ directory."
            )

        try:
            self.model = tf.keras.models.load_model(str(self.model_path))
        except Exception as e:
            print(f"Error loading model: {e}")
            print("Attempting to rebuild architecture and load weights...")
            self.model = build_unet(self.input_shape, self.num_classes)
            self.model.load_weights(str(self.model_path))

    def prepare_tensor(self, image: np.ndarray) -> np.ndarray:
        """Prepares image for model inference (Normalization + Expansion)."""
        # Ensure image is float32 and normalized [0, 1]
        img = image.astype(np.float32) / 255.0
        # Expand dims for batch and channel: (1, 512, 512, 1)
        if len(img.shape) == 2:
            img = np.expand_dims(img, axis=-1)
        tensor = np.expand_dims(img, axis=0)
        return tensor

    def predict(self, tensor: np.ndarray) -> np.ndarray:
        """Runs model prediction."""
        if self.model is None:
            self.load_model()
        return self.model.predict(tensor)

    def decode_segmentation(self, prediction: np.ndarray) -> tuple[np.ndarray, float]:
        """Converts softmax output to class map and calculates mean confidence."""
        # prediction shape: (1, 512, 512, 9)
        class_map = np.argmax(prediction[0], axis=-1).astype(np.uint8)

        # Calculate confidence from probabilities of selected classes
        conf_map = np.max(prediction[0], axis=-1)
        # Average confidence for non-background pixels
        foreground_mask = (class_map > 0)
        if np.any(foreground_mask):
            mean_conf = float(np.mean(conf_map[foreground_mask]))
        else:
            mean_conf = float(np.mean(conf_map))

        return class_map, mean_conf

    def segment_oct(self, preprocessed_image: np.ndarray) -> dict:
        """Complete segmentation pipeline from model-ready image."""
        tensor = self.prepare_tensor(preprocessed_image)
        prediction = self.predict(tensor)

        raw_mask, confidence = self.decode_segmentation(prediction)

        # Post-processing
        processed_mask = PostProcessingService.apply_postprocessing(raw_mask)

        return {
            "mask": processed_mask,
            "confidence": confidence,
            "raw_prediction": prediction
        }
