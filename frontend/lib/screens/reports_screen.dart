import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../providers/app_providers.dart';
import '../widgets/clinical_card.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final historyAsync = ref.watch(analysisHistoryProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reportGenerated,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.downloadPDF} & ${l10n.printReport} — ${l10n.disclaimerNote}',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            historyAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (err, _) => Center(child: Text('Error loading reports: $err')),
              data: (history) {
                if (history.isEmpty) {
                  return ClinicalCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text('No reports generated yet. Run an analysis to generate a PDF report.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: history.map((h) {
                    final reportUid = 'REP-${(h['scan_uid'] ?? '000').replaceAll('OCT-', '')}';
                    return Container(
                      width: 320,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.picture_as_pdf_outlined, color: theme.colorScheme.primary, size: 24),
                              ),
                              StatusBadge.success(label: 'Verified', isDark: isDark),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(reportUid, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('${l10n.name}: ${h['patient_name'] ?? "Patient"}', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                          Text('${l10n.dateRegistered}: ${h['date'] ?? ""}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final analysisId = h['id'] as int;
                                final seg = await ref.read(analysisServiceProvider).getAnalysisResult(analysisId);

                                final report = await ref.read(reportServiceProvider).generateReport(
                                  analysisId,
                                  notes: 'Clinical U-Net retinal layer segmentation verified.',
                                );

                                if (context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ReportPreviewScreen(report: report, segmentation: seg),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                            label: const Text('Preview & Download Report'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 38),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
