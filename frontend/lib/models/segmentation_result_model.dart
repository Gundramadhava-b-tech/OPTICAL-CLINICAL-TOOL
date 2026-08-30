class LayerMeasurementModel {
  final String layerName;
  final int layerIndex;
  final bool isDetected;
  final double meanThicknessPx;
  final double minThicknessPx;
  final double maxThicknessPx;
  final double? meanThicknessUm;
  final double? minThicknessUm;
  final double? maxThicknessUm;
  final int layerAreaPx;
  final double? confidenceScore;
  final String? colorHex;
  final int boundaryPointsCount;

  LayerMeasurementModel({
    required this.layerName,
    required this.layerIndex,
    required this.isDetected,
    required this.meanThicknessPx,
    required this.minThicknessPx,
    required this.maxThicknessPx,
    this.meanThicknessUm,
    this.minThicknessUm,
    this.maxThicknessUm,
    required this.layerAreaPx,
    this.confidenceScore,
    this.colorHex,
    this.boundaryPointsCount = 0,
  });

  factory LayerMeasurementModel.fromJson(Map<String, dynamic> json) {
    return LayerMeasurementModel(
      layerName: json['layer_name'] as String,
      layerIndex: json['layer_index'] as int,
      isDetected: json['is_detected'] as bool? ?? true,
      meanThicknessPx: (json['mean_thickness_px'] as num).toDouble(),
      minThicknessPx: (json['min_thickness_px'] as num).toDouble(),
      maxThicknessPx: (json['max_thickness_px'] as num).toDouble(),
      meanThicknessUm: (json['mean_thickness_um'] as num?)?.toDouble(),
      minThicknessUm: (json['min_thickness_um'] as num?)?.toDouble(),
      maxThicknessUm: (json['max_thickness_um'] as num?)?.toDouble(),
      layerAreaPx: json['layer_area_px'] as int? ?? 0,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      colorHex: json['color_hex'] as String?,
      boundaryPointsCount: json['boundary_points_count'] as int? ?? 0,
    );
  }
}

class SegmentationResultModel {
  final int id;
  final int scanId;
  final int patientId;
  final String patientName;
  final String status;
  final double? confidenceScore;
  final String overallQuality;
  final Map<String, dynamic>? qualityMetrics;
  final double executionTimeMs;
  final String originalImageUrl;
  final String? preprocessedImageUrl;
  final String? maskImageUrl;
  final String? overlayImageUrl;
  final String? findingsSummary;
  final List<LayerMeasurementModel> layers;
  final bool isCalibrated;
  final double? axialCalibrationUm;
  final DateTime createdAt;

  SegmentationResultModel({
    required this.id,
    required this.scanId,
    required this.patientId,
    required this.patientName,
    required this.status,
    this.confidenceScore,
    required this.overallQuality,
    this.qualityMetrics,
    required this.executionTimeMs,
    required this.originalImageUrl,
    this.preprocessedImageUrl,
    this.maskImageUrl,
    this.overlayImageUrl,
    this.findingsSummary,
    required this.layers,
    required this.isCalibrated,
    this.axialCalibrationUm,
    required this.createdAt,
  });

  factory SegmentationResultModel.fromJson(Map<String, dynamic> json) {
    return SegmentationResultModel(
      id: json['id'] as int,
      scanId: json['scan_id'] as int,
      patientId: json['patient_id'] as int,
      patientName: json['patient_name'] as String? ?? 'Patient',
      status: json['status'] as String? ?? 'COMPLETED',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      overallQuality: json['overall_quality'] as String? ?? 'Good',
      qualityMetrics: json['quality_metrics'] as Map<String, dynamic>?,
      executionTimeMs: (json['execution_time_ms'] as num?)?.toDouble() ?? 0.0,
      originalImageUrl: json['original_image_url'] as String? ?? '',
      preprocessedImageUrl: json['preprocessed_image_url'] as String?,
      maskImageUrl: json['mask_image_url'] as String?,
      overlayImageUrl: json['overlay_image_url'] as String?,
      findingsSummary: json['findings_summary'] as String?,
      layers: (json['layers'] as List<dynamic>?)
              ?.map((e) => LayerMeasurementModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isCalibrated: json['is_calibrated'] as bool? ?? false,
      axialCalibrationUm: (json['axial_calibration_um'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class ReportModel {
  final int id;
  final int analysisId;
  final int patientId;
  final String patientName;
  final String reportUid;
  final String pdfUrl;
  final DateTime generatedAt;
  final String? notes;
  final String disclaimer;

  ReportModel({
    required this.id,
    required this.analysisId,
    required this.patientId,
    required this.patientName,
    required this.reportUid,
    required this.pdfUrl,
    required this.generatedAt,
    this.notes,
    required this.disclaimer,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as int,
      analysisId: json['analysis_id'] as int,
      patientId: json['patient_id'] as int,
      patientName: json['patient_name'] as String? ?? 'Patient',
      reportUid: json['report_uid'] as String,
      pdfUrl: json['pdf_url'] as String,
      generatedAt: DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now(),
      notes: json['notes'] as String?,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}
