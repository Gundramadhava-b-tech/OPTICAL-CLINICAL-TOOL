import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../models/patient_model.dart';
import '../providers/app_providers.dart';
import '../widgets/clinical_card.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  final Function(int) onNavigateToUpload;

  const PatientsScreen({super.key, required this.onNavigateToUpload});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final _searchController = TextEditingController();
  String? _selectedGender;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddPatientDialog() {
    final l10n = AppLocalizations.of(context);
    final idCtrl = TextEditingController(text: 'PAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final historyCtrl = TextEditingController();
    final conditionCtrl = TextEditingController(text: 'Macular Evaluation');
    String gender = 'Female';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Icon(Icons.person_add_alt_1_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text(l10n.addPatient, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: idCtrl,
                    decoration: InputDecoration(labelText: l10n.patientId, hintText: 'PAT-90142'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: l10n.name, hintText: 'Eleanor Vance'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ageCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l10n.age, hintText: '64'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: gender,
                          decoration: InputDecoration(labelText: l10n.gender),
                          items: [
                            DropdownMenuItem(value: 'Female', child: Text(l10n.female)),
                            DropdownMenuItem(value: 'Male', child: Text(l10n.male)),
                            DropdownMenuItem(value: 'Other', child: Text(l10n.other)),
                          ],
                          onChanged: (v) => setDialogState(() => gender = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactCtrl,
                    decoration: InputDecoration(labelText: l10n.contact, hintText: '+1 (555) 234-8910'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: conditionCtrl,
                    decoration: InputDecoration(labelText: l10n.eyeCondition, hintText: 'Diabetic Macular Edema Evaluation'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: historyCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: l10n.medicalHistory, hintText: 'Type 2 Diabetes, Pseudophakic OD'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || ageCtrl.text.isEmpty) return;
                try {
                  await ref.read(patientServiceProvider).createPatient({
                    'patient_id': idCtrl.text.trim(),
                    'full_name': nameCtrl.text.trim(),
                    'age': int.tryParse(ageCtrl.text) ?? 50,
                    'gender': gender,
                    'contact': contactCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'medical_history': historyCtrl.text.trim(),
                    'eye_condition': conditionCtrl.text.trim(),
                  });
                  ref.refresh(patientsListProvider);
                  ref.invalidate(dashboardStatsProvider);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.patientCreatedSuccess)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              },
              child: Text(l10n.savePatientRecord),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final patientsAsync = ref.watch(patientsListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.patients,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.patientDetails}, ${l10n.scanHistory} & ${l10n.layerThicknessMetrics}',
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddPatientDialog,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(l10n.addPatient),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search and Filter Card
            ClinicalCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search patients by Name, ID, or Indication...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 140,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedGender,
                        hint: Text(l10n.gender, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.allGenders)),
                          DropdownMenuItem(value: 'Female', child: Text(l10n.female)),
                          DropdownMenuItem(value: 'Male', child: Text(l10n.male)),
                          DropdownMenuItem(value: 'Other', child: Text(l10n.other)),
                        ],
                        onChanged: (v) => setState(() => _selectedGender = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Patients Table
            patientsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Error loading patients: $err', style: const TextStyle(color: AppColors.error)),
              ),
              data: (patients) {
                final query = _searchController.text.toLowerCase().trim();
                final filtered = patients.where((p) {
                  final matchesSearch = query.isEmpty ||
                      p.fullName.toLowerCase().contains(query) ||
                      p.patientId.toLowerCase().contains(query) ||
                      (p.eyeCondition ?? '').toLowerCase().contains(query);
                  final matchesGender = _selectedGender == null || p.gender == _selectedGender;
                  return matchesSearch && matchesGender;
                }).toList();

                if (filtered.isEmpty) {
                  return ClinicalCard(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.person_search_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text('No patients found matching your search.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        ],
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
                        headingRowColor: MaterialStateProperty.all(theme.colorScheme.surfaceVariant),
                        headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 13),
                        dataTextStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                        columns: [
                          DataColumn(label: Text(l10n.patientId)),
                          DataColumn(label: Text(l10n.name)),
                          DataColumn(label: Text(l10n.age)),
                          DataColumn(label: Text(l10n.gender)),
                          DataColumn(label: Text(l10n.eyeCondition)),
                          DataColumn(label: Text(l10n.dateRegistered)),
                          const DataColumn(label: Text('Actions')),
                        ],
                        rows: filtered.map((p) {
                          final dateStr = p.createdAt != null
                              ? DateFormat('yyyy-MM-dd').format(p.createdAt!)
                              : 'Recently';

                          return DataRow(
                            cells: [
                              DataCell(Text(p.patientId, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                                      child: Text(
                                        p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'P',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              DataCell(Text('${p.age}')),
                              DataCell(Text(p.gender)),
                              DataCell(Text(p.eyeCondition ?? 'General OCT')),
                              DataCell(Text(dateStr)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.cloud_upload_outlined, size: 18, color: theme.colorScheme.primary),
                                      tooltip: l10n.uploadOCT,
                                      onPressed: () {
                                        ref.read(selectedPatientIdProvider.notifier).state = p.id;
                                        widget.onNavigateToUpload(2); // Go to Upload screen
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                      tooltip: 'Delete Patient',
                                      onPressed: () => _confirmDelete(p),
                                    ),
                                  ],
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

  void _confirmDelete(PatientModel p) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient Record?'),
        content: Text('${l10n.confirmDeletePatient}\nPatient: ${p.fullName} (${p.patientId})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              try {
                await ref.read(patientServiceProvider).deletePatient(p.id);
                ref.refresh(patientsListProvider);
                ref.invalidate(dashboardStatsProvider);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patient record removed.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
