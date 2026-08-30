# CLAHE: Contrast Limited Adaptive Histogram Equalization

## Mathematical Principle
**CLAHE** is used to improve local contrast and enhance the definitions of edges in images with non-uniform illumination, which is common in OCT scans.

## Parameters
- **Tile Grid Size**: 8x8. The image is divided into small contextual regions.
- **Clip Limit**: 2.5. This limit prevents over-amplification of noise in homogeneous regions (like the vitreous or choroid) by clipping the histogram at a specific height and redistributing the clipped pixels.

## Result
Enhances the visibility of thin layers like the ILM and IS/OS junction without introducing significant artifacts.
