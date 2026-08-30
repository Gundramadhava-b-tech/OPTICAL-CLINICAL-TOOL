# Grayscale Standardization

## Mathematical Principle
Ophthalmic images (DICOM/PNG) may be stored in RGB format. AI inference requires single-channel intensity maps. The standardization uses the CCIR 601 luminance formula:

$$I_{\text{gray}} = 0.299 \cdot R + 0.587 \cdot G + 0.114 \cdot B$$

## Implementation
- **Input**: 24-bit 3-channel RGB.
- **Output**: 8-bit 1-channel luminance matrix.
- **Normalization**: Ensures that color artifacts from device-specific screen captures do not bias the neural network's tissue perception.
