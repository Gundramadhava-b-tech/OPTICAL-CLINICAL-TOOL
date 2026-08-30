import os
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).resolve().parent
INPUT_DIR = BASE_DIR / "input"
OUTPUT_DIR = BASE_DIR / "output"
MODELS_DIR = BASE_DIR / "models"

# Ensure directories exist
for d in [INPUT_DIR, OUTPUT_DIR, MODELS_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# Model Configuration
INPUT_HEIGHT = 512
INPUT_WIDTH = 512
NUM_CLASSES = 9  # Background + 8 Retinal Layers

# Default Model Path
MODEL_PATH = MODELS_DIR / "retina_unet_v1.h5"

# Retinal Layer Classes
# 0 = Background, 1 = ILM, 2 = RNFL, 3 = GCL, 4 = IPL, 5 = INL, 6 = OPL, 7 = ONL, 8 = RPE
LAYER_CLASSES = [
    "Background",
    "ILM",
    "RNFL",
    "GCL",
    "IPL",
    "INL",
    "OPL",
    "ONL",
    "RPE"
]

# RGBA for visualization
LAYER_COLORS = {
    "ILM":  (255, 23, 68, 255),    # #FF1744
    "RNFL": (255, 145, 0, 255),   # #FF9100
    "GCL":  (255, 234, 0, 255),   # #FFEA00
    "IPL":  (0, 230, 118, 255),   # #00E676
    "INL":  (0, 176, 255, 255),   # #00B0FF
    "OPL":  (101, 31, 255, 255),  # #651FFF
    "ONL":  (213, 0, 249, 255),   # #D500F9
    "RPE":  (245, 0, 87, 255),    # #F50057
}

# Axial Calibration
AXIAL_CALIBRATION_UM_PER_PIXEL = 3.87
CALIBRATION_SOURCE = "Standard Ophthalmic OCT Standard (Heidelberg/Cirrus Default)"
