import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';
import '../config/app_config.dart';
import '../models/report_model.dart';
import '../models/segmentation_result_model.dart';
import '../widgets/clinical_card.dart';
import '../widgets/thickness_table_widget.dart';

class ReportPreviewScreen extends StatelessWidget {
  final ReportModel report;
  final SegmentationResultModel segmentation;

  const ReportPreviewScreen({
    super.key,
    required this.report,
    required this.segmentation,
  });

  String _resolveDownloadUrl() {
    if (report.pdfUrl.startsWith('http')) return report.pdfUrl;
    return '${AppConfig.baseUrl}${report.pdfUrl}';
  }

  Widget _buildImagePanel(String label, String url, double width) {
    final fullUrl = url.startsWith('http') ? url : '${AppConfig.baseUrl}$url';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Container(
          width: width,
          height: width * 0.6,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              fullUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image_outlined, color: Colors.white24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.preview, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('Report ID: ${report.reportUid} • ${l10n.name}: ${report.patientName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l10n.downloadPDF} (${report.reportUid})')),
              );
            },
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(l10n.downloadPDF),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Theme(
              // Force light theme for the report content regardless of system theme
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(primary: AppColors.primary),
              ),
              child: ClinicalCard(
                backgroundColor: Colors.white,
                borderColor: Colors.grey.withOpacity(0.3),
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RetinaSeg AI',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Text(
                              l10n.appSubtitle,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Report UID: ${report.reportUid}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                            Text('Generated: ${report.generatedAt.toString().substring(0, 16)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1.5, color: AppColors.primary),
                    const SizedBox(height: 16),

                  // Patient & Scan Meta Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PATIENT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const SizedBox(height: 6),
                              Text('${l10n.name}: ${report.patientName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                              const Text('Patient ID: PAT-90142', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SCAN PARAMETERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const SizedBox(height: 6),
                              Text('${l10n.eyeLaterality}: OD (${l10n.rightEye})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                              Text('${l10n.axialCalibration}: ${segmentation.axialCalibrationUm ?? 3.87} μm/px', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4-Panel OCT Image Grid
                  const Text('OPHTHALMIC IMAGING QUAD-VIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  LayoutBuilder(builder: (context, constraints) {
                    final imgWidth = (constraints.maxWidth - 12) / 2;
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildImagePanel('1. Original Scan', segmentation.originalImageUrl, imgWidth),
                            _buildImagePanel('2. CLAHE Enhanced', segmentation.preprocessedImageUrl ?? segmentation.originalImageUrl, imgWidth),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildImagePanel('3. Segmentation Mask', segmentation.maskImageUrl ?? '', imgWidth),
                            _buildImagePanel('4. Boundary Overlay', segmentation.overlayImageUrl ?? '', imgWidth),
                          ],
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),

                  // Quantitative Measurements
                  const Text('QUANTITATIVE LAYER THICKNESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  ThicknessTableWidget(
                    layers: segmentation.layers,
                    isCalibrated: segmentation.isCalibrated,
                    calibrationFactorUm: segmentation.axialCalibrationUm,
                  ),
                  const SizedBox(height: 24),

                  // Clinical Findings
                  const Text('CLINICAL FINDINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      segmentation.findingsSummary ?? 'Continuous retinal microstructural boundaries detected without focal atrophy or macular edema.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Legal Disclaimer
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    AppConstants.clinicalDisclaimer,
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
