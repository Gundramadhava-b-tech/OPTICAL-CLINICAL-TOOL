# U-Net: Deep Learning Segmentation Architecture

## Concept
The **U-Net** is a convolutional neural network (CNN) designed for fast and precise image segmentation. It features a symmetric "U" shape consisting of a contracting path (encoder) and an expansive path (decoder).

## Architecture Details
- **Encoder (Contracting Path)**: Captures context via successive 3x3 convolutions, Batch Normalization, ReLU, and 2x2 Max Pooling.
- **Bottleneck**: The deepest layer representing high-level abstract features (typically 1024 filters).
- **Decoder (Expansive Path)**: Enables precise localization using up-convolutions (transposed convolutions) and skip connections.
- **Skip Connections**: Concatenate feature maps from the encoder to the decoder to preserve high-resolution spatial details lost during pooling.
- **Output Layer**: A 1x1 convolution with Softmax activation to generate a probability map for 9 classes (8 layers + 1 background).
