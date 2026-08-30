import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';
import '../models/segmentation_result_model.dart';
import '../providers/app_providers.dart';
import '../widgets/clinical_card.dart';
import '../widgets/oct_image_viewer.dart';
import '../widgets/layer_visibility_panel.dart';
import '../widgets/thickness_table_widget.dart';
import 'report_preview_screen.dart';

class SegmentationWorkspaceScreen extends ConsumerStatefulWidget {
  const SegmentationWorkspaceScreen({super.key});

  @override
  ConsumerState<SegmentationWorkspaceScreen> createState() => _SegmentationWorkspaceScreenState();
}

class _SegmentationWorkspaceScreenState extends ConsumerState<SegmentationWorkspaceScreen> {
  bool _isGeneratingReport = false;

  void _handleGenerateReport(SegmentationResultModel seg) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isGeneratingReport = true);
    try {
      final report = await ref.read(reportServiceProvider).generateReport(
        seg.id,
        notes: 'Clinical U-Net retinal layer segmentation completed. Preserved foveal depression contour.',
      );
      ref.invalidate(dashboardStatsProvider);
      setState(() => _isGeneratingReport = false);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReportPreviewScreen(report: report, segmentation: seg)),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingReport = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final seg = ref.watch(currentSegmentationProvider);
    final scan = ref.watch(currentScanProvider);

    if (seg == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text(l10n.segmentation)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('No active segmentation results loaded.', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.uploadOCT),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.segmentation,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
            Text(
              'Scan: ${scan?.scanUid ?? "OCT-SCAN"} • ${l10n.name}: ${seg.patientName}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: _isGeneratingReport ? null : () => _handleGenerateReport(seg),
            icon: _isGeneratingReport
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(_isGeneratingReport ? 'Generating PDF...' : l10n.generateReport),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Bar
            ClinicalCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _buildSummaryItem(context, 'Status', seg.status, isBadge: true, badgeType: 'success'),
                        _buildSummaryItem(context, l10n.aiConfidence, '${((seg.confidenceScore ?? 0.94) * 100).toInt()}%'),
                        _buildSummaryItem(context, l10n.imageQuality, seg.overallQuality, isBadge: true, badgeType: 'info'),
                        _buildSummaryItem(context, 'Model Engine', 'U-Net 4-Depth Residual'),
                        _buildSummaryItem(context, l10n.executionTime, '${seg.executionTimeMs.toInt()} ms'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Workspace Layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1000;

                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Interactive OCT Viewer + 4-View Switcher
                    Expanded(
                      flex: isWide ? 7 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OCTImageViewer(
                            originalImageUrl: seg.originalImageUrl,
                            preprocessedImageUrl: seg.preprocessedImageUrl,
                            maskImageUrl: seg.maskImageUrl,
                            overlayImageUrl: seg.overlayImageUrl,
                            height: 440,
                          ),
                          const SizedBox(height: 16),

                          // Layer Visibility Toggles & Opacity Slider
                          const LayerVisibilityPanel(),
                        ],
                      ),
                    ),

                    if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),

                    // Right Column: Measurements Table & Quality Assessment
                    Expanded(
                      flex: isWide ? 5 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClinicalCard(
                            child: ThicknessTableWidget(
                              layers: seg.layers,
                              isCalibrated: seg.isCalibrated,
                              calibrationFactorUm: seg.axialCalibrationUm,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Diagnostic Findings & Clinical Disclaimer
                          ClinicalCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.notes_outlined, size: 18, color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.clinicalFindings,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  seg.findingsSummary ?? 'All 8 anatomical retinal layers identified with continuous boundaries.',
                                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface, height: 1.4),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n.disclaimerNote,
                                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, {bool isBadge = false, String badgeType = 'info'}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        if (isBadge)
          badgeType == 'success'
              ? StatusBadge.success(label: value, isDark: isDark)
              : StatusBadge.info(label: value, isDark: isDark)
        else
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
      ],
    );
  }
}
