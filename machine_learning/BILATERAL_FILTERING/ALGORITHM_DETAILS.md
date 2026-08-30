# Bilateral Filtering: Edge-Preserving Denoising

## Concept
Standard Gaussian blurring smooths noise but also blurs critical layer boundaries. **Bilateral Filtering** solves this by considering both the spatial distance and the intensity difference between pixels.

## Parameters
- **Diameter (d)**: 9. The pixel neighborhood size.
- **Sigma Color**: 75. A larger value means that farther colors within the pixel neighborhood will be mixed together, resulting in larger areas of semi-equal color.
- **Sigma Space**: 75. A larger value means that farther pixels will influence each other as long as their colors are close enough.

## Advantage in OCT
Suppresses destructive speckle noise while maintaining the razor-sharp intensity gradients required to delineate retinal sub-layers.
