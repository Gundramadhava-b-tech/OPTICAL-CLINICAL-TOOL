class AppConstants {
  static const String appName = 'RetinaSeg AI';
  static const String appTagline = 'Automated Retinal Layer Segmentation in OCT Images';
  static const String appSubtitle = 'Advanced Ophthalmic Diagnostics Powered by Enhanced Preprocessing & U-Net Deep Learning';
  static const String appVersion = 'v1.4.2 (Clinical Edition)';

  // Default API Endpoint
  static const String defaultApiBaseUrl = 'http://127.0.0.1:8000';

  // Calibration Defaults (Heidelberg/Cirrus standard)
  static const double defaultAxialCalibrationUm = 3.87;

  // Maximum allowed upload size (25 MB)
  static const int maxUploadSizeBytes = 25 * 1024 * 1024;

  // Allowed file extensions
  static const List<String> allowedExtensions = ['png', 'jpg', 'jpeg', 'tif', 'tiff', 'bmp'];

  // Medical Disclaimer
  static const String clinicalDisclaimer = 
      'AI assistance only — results are intended for research and decision-support purposes and do not replace professional ophthalmic diagnosis.';

  // Retinal Layer Full Class Names & Details
  static const List<String> retinalLayers = [
    'ILM',   // Inner Limiting Membrane
    'RNFL',  // Retinal Nerve Fiber Layer
    'GCL',   // Ganglion Cell Layer
    'IPL',   // Inner Plexiform Layer
    'INL',   // Inner Nuclear Layer
    'OPL',   // Outer Plexiform Layer
    'ONL',   // Outer Nuclear Layer
    'RPE',   // Retinal Pigment Epithelium
  ];

  static const Map<String, String> layerFullNames = {
    'ILM': 'Inner Limiting Membrane',
    'RNFL': 'Retinal Nerve Fiber Layer',
    'GCL': 'Ganglion Cell Layer',
    'IPL': 'Inner Plexiform Layer',
    'INL': 'Inner Nuclear Layer',
    'OPL': 'Outer Plexiform Layer',
    'ONL': 'Outer Nuclear Layer & IS',
    'RPE': 'Retinal Pigment Epithelium & OS',
  };

  static const Map<String, String> layerDescriptions = {
    'ILM': 'Vitreoretinal interface boundary separating vitreous from nerve fibers.',
    'RNFL': 'Axons of retinal ganglion cells coursing to the optic nerve head.',
    'GCL': 'Cell bodies of ganglion cells; vital for glaucoma & optic neuropathy evaluation.',
    'IPL': 'Synaptic connections between bipolar/amacrine cells and ganglion cells.',
    'INL': 'Cell bodies of horizontal, bipolar, and amacrine interneurons.',
    'OPL': 'Synapses between photoreceptors and bipolar/horizontal cells.',
    'ONL': 'Photoreceptor cell nuclei (rods & cones) and inner segments.',
    'RPE': 'Hexagonal pigment epithelial monolayer providing metabolic support to photoreceptors.',
  };
}
