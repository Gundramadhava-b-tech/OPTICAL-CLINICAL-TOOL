# Suzuki-Abe Border Following Algorithm

## Concept
Once the AI generates a pixel-wise mask, clinical reports require smooth, continuous vector boundaries. The **Suzuki-Abe algorithm** is the standard topological approach for extracting hierarchical contours from binary images.

## Mathematical Principle
- It uses a border-following technique to establish parent-child relationships between boundaries.
- **Complexity**: $O(N)$ where $N$ is the number of pixels in the image.

## Use in RetinaSeg
- Converts the discrete 512x512 mask into mathematical splines.
- Enables the drawing of precise colored lines (ILM, RPE, etc.) on the final overlay image using `cv2.drawContours`.
- Facilitates the extraction of boundary points for curvature and smoothness analysis.
