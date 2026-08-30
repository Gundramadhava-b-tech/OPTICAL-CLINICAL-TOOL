# Retinal Thickness Clinical Calibration

## Concept
AI models measure layer thickness in pixels ($px$). However, ophthalmologists require measurements in physical micrometers ($\mu m$) for diagnostic reporting.

## Formulation
The physical thickness $t_{\mu m}$ at a given A-scan column $x$ is:
$$t_{\mu m}(x) = (y_{\text{bottom}} - y_{\text{top}}) \times c$$

where $c$ is the **Axial Calibration Factor**.

## Default Parameters
- **Standard Factor**: $3.87\,\mu m / \text{pixel}$ (Standard for Spectralis/Cirrus axial resolution).
- **Metric Extraction**:
  - **Mean Thickness**: $\frac{1}{W} \sum t_{\mu m}(x)$
  - **Min/Max Thickness**: The peak and trough of the layer profile.
  - **Total Retinal Thickness (TRT)**: Distance from ILM to RPE floor.
