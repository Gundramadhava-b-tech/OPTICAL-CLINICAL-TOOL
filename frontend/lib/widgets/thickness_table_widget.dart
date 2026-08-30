import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../models/layer_measurement_model.dart';

class ThicknessTableWidget extends StatelessWidget {
  final List<LayerMeasurementModel> layers;
  final bool isCalibrated;
  final double? calibrationFactorUm;

  const ThicknessTableWidget({
    super.key,
    required this.layers,
    required this.isCalibrated,
    this.calibrationFactorUm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (layers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'No segmentation layer metrics available.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.layerThicknessMetrics,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (isCalibrated)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${l10n.calibrated} (${calibrationFactorUm ?? 3.87} μm/px)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF34D399) : AppColors.success,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF78350F) : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.uncalibrated,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFFBBF24) : AppColors.warning,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(theme.colorScheme.primary.withOpacity(0.12)),
                headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 13),
                dataTextStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                columnSpacing: 24,
                columns: [
                  DataColumn(label: Text(l10n.layer)),
                  const DataColumn(label: Text('Status')),
                  DataColumn(label: Text(l10n.mean)),
                  DataColumn(label: Text(l10n.min)),
                  DataColumn(label: Text(l10n.max)),
                  DataColumn(label: Text(l10n.area)),
                  const DataColumn(label: Text('Confidence')),
                ],
                rows: layers.map((l) {
                  final layerColor = AppColors.getLayerColor(l.layerName);
                  final meanStr = isCalibrated && l.meanThicknessUm != null
                      ? '${l.meanThicknessUm} μm'
                      : '${l.meanThicknessPx} px';
                  final minStr = isCalibrated && l.minThicknessUm != null
                      ? '${l.minThicknessUm} μm'
                      : '${l.minThicknessPx} px';
                  final maxStr = isCalibrated && l.maxThicknessUm != null
                      ? '${l.maxThicknessUm} μm'
                      : '${l.maxThicknessPx} px';
                  final confStr = l.confidenceScore != null
                      ? '${(l.confidenceScore! * 100).toInt()}%'
                      : '—';

                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: layerColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(l.layerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          l.isDetected ? 'Detected' : 'Not Detected',
                          style: TextStyle(
                            color: l.isDetected ? (isDark ? const Color(0xFF34D399) : AppColors.success) : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(Text(meanStr, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(minStr)),
                      DataCell(Text(maxStr)),
                      DataCell(Text('${l.layerAreaPx} px²')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            confStr,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
