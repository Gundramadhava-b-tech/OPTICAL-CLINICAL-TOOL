import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/clinical_card.dart';
import 'segmentation_workspace_screen.dart';

class AnalysisHistoryScreen extends ConsumerStatefulWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  ConsumerState<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends ConsumerState<AnalysisHistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _viewAnalysis(int analysisId) async {
    try {
      final seg = await ref.read(analysisServiceProvider).getAnalysisResult(analysisId);
      ref.read(currentSegmentationProvider.notifier).state = seg;
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SegmentationWorkspaceScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load analysis: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(analysisHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Text(
              'OCT Analysis History',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Audit log and retrospective records of all completed retinal layer segmentations.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Search Bar
            ClinicalCard(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by Patient Name or Scan UID...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(height: 20),

            // History Table
            historyAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (err, _) => Center(child: Text('Error loading history: $err')),
              data: (history) {
                final filtered = history.where((h) {
                  final search = _searchController.text.toLowerCase();
                  return search.isEmpty ||
                      (h['patient_name']?.toString().toLowerCase().contains(search) ?? false) ||
                      (h['scan_uid']?.toString().toLowerCase().contains(search) ?? false);
                }).toList();

                if (filtered.isEmpty) {
                  return ClinicalCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.history_toggle_off, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('No previous OCT analyses match your query.', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ClinicalCard(
                  padding: const EdgeInsets.all(0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(AppColors.primaryLight.withOpacity(0.5)),
                        headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13),
                        dataTextStyle: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        columns: const [
                          DataColumn(label: Text('Scan UID')),
                          DataColumn(label: Text('Patient Name')),
                          DataColumn(label: Text('Date & Time')),
                          DataColumn(label: Text('Scan Type')),
                          DataColumn(label: Text('Segmentation Conf')),
                          DataColumn(label: Text('Quality')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: filtered.map((h) {
                          final analysisId = h['id'] as int;
                          return DataRow(
                            cells: [
                              DataCell(Text(h['scan_uid'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(h['patient_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(h['date'] ?? 'N/A')),
                              DataCell(Text(h['scan_type'] ?? 'OCT B-Scan')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    h['confidence_score'] ?? '95%',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 11),
                                  ),
                                ),
                              ),
                              DataCell(StatusBadge.info(label: h['overall_quality'] ?? 'Good')),
                              DataCell(
                                ElevatedButton.icon(
                                  onPressed: () => _viewAnalysis(analysisId),
                                  icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                                  label: const Text('View Result'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
