# Min-Max Dynamic Range Normalization

## Concept
OCT signal intensities can vary significantly between devices (Heidelberg vs. Zeiss). **Min-Max Normalization** standardizes the intensity range of the B-scan to ensure the AI model receives data within a consistent distribution.

## Formulation
For each pixel $(x, y)$:
$$I_{\text{norm}}(x, y) = \frac{I(x, y) - I_{\min}}{I_{\max} - I_{\min}} \times 255$$

## Implementation Details
- Handles edge cases where $I_{\max} = I_{\min}$ (blank image) to prevent division-by-zero.
- Ensures the final tensor is strictly within the $[0, 255]$ range before being cast to float32 for neural inference.
