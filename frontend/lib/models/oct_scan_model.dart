class OCTScanModel {
  final int id;
  final String scanUid;
  final int patientId;
  final String? patientName;
  final String originalFilename;
  final String fileUrl;
  final int fileSizeBytes;
  final int width;
  final int height;
  final String eyeLaterality;
  final String deviceManufacturer;
  final double? axialResolutionUm;
  final String validationStatus;
  final double? validationScore;
  final Map<String, dynamic>? validationDetails;
  final DateTime createdAt;

  OCTScanModel({
    required this.id,
    required this.scanUid,
    required this.patientId,
    this.patientName,
    required this.originalFilename,
    required this.fileUrl,
    required this.fileSizeBytes,
    required this.width,
    required this.height,
    required this.eyeLaterality,
    required this.deviceManufacturer,
    this.axialResolutionUm,
    required this.validationStatus,
    this.validationScore,
    this.validationDetails,
    required this.createdAt,
  });

  bool get isValid => validationStatus == 'VALID';

  factory OCTScanModel.fromJson(Map<String, dynamic> json) {
    return OCTScanModel(
      id: json['id'] as int,
      scanUid: json['scan_uid'] as String,
      patientId: json['patient_id'] as int,
      patientName: json['patient_name'] as String?,
      originalFilename: json['original_filename'] as String,
      fileUrl: json['file_url'] as String,
      fileSizeBytes: json['file_size_bytes'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
      eyeLaterality: json['eye_laterality'] as String? ?? 'OD',
      deviceManufacturer: json['device_manufacturer'] as String? ?? 'Spectralis/Cirrus',
      axialResolutionUm: (json['axial_resolution_um'] as num?)?.toDouble(),
      validationStatus: json['validation_status'] as String? ?? 'PENDING',
      validationScore: (json['validation_score'] as num?)?.toDouble(),
      validationDetails: json['validation_details'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class PreprocessingModel {
  final int id;
  final int scanId;
  final String originalImageUrl;
  final String preprocessedImageUrl;
  final List<String> methodsApplied;
  final double? noiseReductionSnr;
  final double? contrastEnhancementRatio;
  final double executionTimeMs;
  final DateTime createdAt;

  PreprocessingModel({
    required this.id,
    required this.scanId,
    required this.originalImageUrl,
    required this.preprocessedImageUrl,
    required this.methodsApplied,
    this.noiseReductionSnr,
    this.contrastEnhancementRatio,
    required this.executionTimeMs,
    required this.createdAt,
  });

  factory PreprocessingModel.fromJson(Map<String, dynamic> json) {
    return PreprocessingModel(
      id: json['id'] as int,
      scanId: json['scan_id'] as int,
      originalImageUrl: json['original_image_url'] as String,
      preprocessedImageUrl: json['preprocessed_image_url'] as String,
      methodsApplied: (json['methods_applied'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      noiseReductionSnr: (json['noise_reduction_snr'] as num?)?.toDouble(),
      contrastEnhancementRatio: (json['contrast_enhancement_ratio'] as num?)?.toDouble(),
      executionTimeMs: (json['execution_time_ms'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
