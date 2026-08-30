import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';
import '../providers/app_providers.dart';
import '../widgets/clinical_card.dart';

class DashboardScreen extends ConsumerWidget {
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinical Welcome Banner
            ClinicalCard(
              backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.primaryDark,
              borderColor: theme.colorScheme.primary.withOpacity(0.3),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user?.role ?? l10n.ophthalmologistRole,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${l10n.activeSession}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${l10n.welcomeText}, ${user?.fullName ?? "Doctor"}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${l10n.appSubtitle}. Model version: ${AppConstants.appVersion}',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => onNavigate(2), // Navigate to Upload OCT
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: Text(l10n.uploadOCT),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Metrics Cards
            statsAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading your clinical metrics...',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF7F1D1D).withOpacity(0.4) : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Unable to load dashboard data',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$err',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.refresh(dashboardStatsProvider),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (stats) {
                final totalPatients = stats['total_patients'] ?? 0;
                final totalScans = stats['total_scans'] ?? 0;
                final analysesCompleted = stats['analyses_completed'] ?? 0;
                final reportsGenerated = stats['reports_generated'] ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = constraints.maxWidth < 600
                            ? double.infinity
                            : (constraints.maxWidth < 1100 ? (constraints.maxWidth - 20) / 2 : (constraints.maxWidth - 60) / 4);

                        return Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            _buildStatCard(context, l10n.totalPatients, '$totalPatients', Icons.people_alt_outlined, theme.colorScheme.primary, cardWidth),
                            _buildStatCard(context, l10n.totalOCTScans, '$totalScans', Icons.scanner_outlined, const Color(0xFF00897B), cardWidth),
                            _buildStatCard(context, l10n.analysesCompleted, '$analysesCompleted', Icons.check_circle_outline, const Color(0xFF0D9488), cardWidth),
                            _buildStatCard(context, l10n.reportsGenerated, '$reportsGenerated', Icons.picture_as_pdf_outlined, const Color(0xFF0284C7), cardWidth),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Empty Patients Guidance Banner (if 0 patients)
                    if (totalPatients == 0) ...[
                      ClinicalCard(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderColor: theme.colorScheme.primary.withOpacity(0.2),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person_add_alt_1, color: theme.colorScheme.primary, size: 32),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No Patients Yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "You haven't added any patients yet. Add your first patient to begin OCT analysis.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => onNavigate(1), // Go to Patients Screen
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Patient'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Quick Actions Row
                    ClinicalCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            '${l10n.quickActions}:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                ActionChip(
                                  avatar: const Icon(Icons.person_add_outlined, size: 16),
                                  label: Text(l10n.addPatient),
                                  onPressed: () => onNavigate(1),
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.upload_file_outlined, size: 16),
                                  label: Text(l10n.uploadOCT),
                                  onPressed: () => onNavigate(2),
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
                                  label: Text(l10n.startAnalysis),
                                  onPressed: () => onNavigate(3),
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.description_outlined, size: 16),
                                  label: Text(l10n.reports),
                                  onPressed: () => onNavigate(5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recent Analyses Table
                    ClinicalCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.recentAnalyses,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => onNavigate(4),
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: Text(l10n.viewAllHistory),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildRecentAnalysesTable(context, stats['recent_analyses'] as List? ?? []),
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

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, double width) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAnalysesTable(BuildContext context, List analyses) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (analyses.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.biotech_outlined, size: 36, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text(
              'No analyses available',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Analysis results will appear here after you upload and process an OCT scan.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(theme.colorScheme.surfaceVariant),
        headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 13),
        dataTextStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
        columns: [
          DataColumn(label: Text(l10n.patientId)),
          DataColumn(label: Text(l10n.name)),
          const DataColumn(label: Text('Scan UID')),
          const DataColumn(label: Text('Eye')),
          const DataColumn(label: Text('Status')),
          const DataColumn(label: Text('Confidence')),
          const DataColumn(label: Text('Date & Time')),
        ],
        rows: analyses.map((a) {
          return DataRow(
            cells: [
              DataCell(Text(a['patient_mrn'] ?? a['patient_id'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(a['patient_name'] ?? 'N/A')),
              DataCell(Text(a['scan_uid'] ?? 'N/A')),
              DataCell(Text(a['eye_laterality'] ?? 'OD')),
              DataCell(
                StatusBadge.success(
                  label: a['status'] ?? 'COMPLETED',
                  isDark: theme.brightness == Brightness.dark,
                ),
              ),
              DataCell(Text(a['confidence'] != null ? '${(a['confidence'] * 100).toInt()}%' : (a['result'] ?? '96%'))),
              DataCell(Text(a['date'] ?? (a['created_at'] != null ? a['created_at'].toString().substring(0, 16) : 'Just now'))),
            ],
          );
        }).toList(),
      ),
    );
  }
}
