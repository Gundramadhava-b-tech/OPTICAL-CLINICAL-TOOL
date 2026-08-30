import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';
import '../models/patient_model.dart';
import '../models/oct_scan_model.dart';
import '../providers/app_providers.dart';
import '../widgets/clinical_card.dart';

class UploadOCTScreen extends ConsumerStatefulWidget {
  final Function(int) onNavigateToAnalysis;

  const UploadOCTScreen({super.key, required this.onNavigateToAnalysis});

  @override
  ConsumerState<UploadOCTScreen> createState() => _UploadOCTScreenState();
}

class _UploadOCTScreenState extends ConsumerState<UploadOCTScreen> {
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  int? _selectedFileSize;
  
  String _eyeLaterality = 'OD';
  String _deviceManufacturer = 'Heidelberg Spectralis OCT';
  double _axialCalibrationUm = AppConstants.defaultAxialCalibrationUm;
  
  bool _isValidating = false;
  bool _isUploading = false;
  Map<String, dynamic>? _validationResult;
  String? _errorMessage;

  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
      _validationResult = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedExtensions,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      setState(() {
        _selectedFileBytes = file.bytes;
        _selectedFileName = file.name;
        _selectedFileSize = file.size;
        _isValidating = true;
      });

      // Run standalone validation
      try {
        final valRes = await ref.read(octServiceProvider).validateScanOnly(
          file.bytes!,
          file.name,
        );
        setState(() {
          _validationResult = valRes;
          _isValidating = false;
        });
      } catch (e) {
        setState(() {
          _isValidating = false;
          _errorMessage = 'Validation service encountered an issue: $e';
        });
      }
    }
  }

  void _loadSample(String sampleKey) async {
    setState(() {
      _selectedFileBytes = null;
      _selectedFileName = 'Loading $sampleKey...';
      _validationResult = null;
      _errorMessage = null;
      _isValidating = true;
    });

    try {
      final sample = AppConstants.sampleScans.firstWhere((s) => s['id'] == sampleKey);
      final bytes = await DefaultAssetBundle.of(context).load(sample['path']!);
      final data = bytes.buffer.asUint8List();

      setState(() {
        _selectedFileBytes = data;
        _selectedFileName = sample['filename'];
        _selectedFileSize = data.lengthInBytes;
        _eyeLaterality = sample['laterality'] ?? 'OD';
        _deviceManufacturer = sample['device'] ?? 'Heidelberg Spectralis OCT';
        _axialCalibrationUm = (sample['calibration'] as num?)?.toDouble() ?? 3.87;
        _isValidating = true;
      });

      final valRes = await ref.read(octServiceProvider).validateScanOnly(
        data,
        sample['filename']!,
      );
      setState(() {
        _validationResult = valRes;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _errorMessage = 'Failed to load sample: $e';
      });
    }
  }

  void _startAnalysisPipeline() async {
    final l10n = AppLocalizations.of(context);
    final selectedPatient = ref.read(selectedPatientProvider);
    if (selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.patientRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validOCTRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final scan = await ref.read(octServiceProvider).uploadScan(
        patientId: selectedPatient.id,
        fileBytes: _selectedFileBytes!,
        fileName: _selectedFileName ?? 'oct_scan.png',
        eyeLaterality: _eyeLaterality,
        deviceManufacturer: _deviceManufacturer,
        axialResolutionUm: _axialCalibrationUm,
      );

      ref.read(currentOCTScanProvider.notifier).state = scan;
      ref.invalidate(dashboardStatsProvider);
      setState(() => _isUploading = false);

      // Navigate to AI Analysis execution screen
      widget.onNavigateToAnalysis(3);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final patientsAsync = ref.watch(patientsListProvider);
    final selectedPatient = ref.watch(selectedPatientProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header
            Text(
              l10n.uploadOCT,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.dropzonePrompt} (${l10n.supportedFormats})',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ],
                ),
              ),

            // Main Two-Column Layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 850;

                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Patient & Acquisition Parameters
                    Expanded(
                      flex: isWide ? 4 : 0,
                      child: ClinicalCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.acquisitionParameters,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 16),

                            // Patient Selector Dropdown
                            Text(l10n.patientDetails, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 6),
                            patientsAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) => const Text('Error loading patients list'),
                              data: (patients) {
                                return DropdownButtonFormField<PatientModel>(
                                  value: selectedPatient,
                                  isExpanded: true,
                                  hint: Text('Select Patient...', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                                  items: patients.map((p) {
                                    return DropdownMenuItem<PatientModel>(
                                      value: p,
                                      child: Text('${p.patientId} – ${p.fullName} (${p.age}y / ${p.gender})'),
                                    );
                                  }).toList(),
                                  onChanged: (p) => ref.read(selectedPatientProvider.notifier).state = p,
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Eye Laterality OD / OS
                            Text(l10n.eyeLaterality, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: Center(child: Text(l10n.rightEye)),
                                    selected: _eyeLaterality == 'OD',
                                    onSelected: (s) => setState(() => _eyeLaterality = 'OD'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ChoiceChip(
                                    label: Center(child: Text(l10n.leftEye)),
                                    selected: _eyeLaterality == 'OS',
                                    onSelected: (s) => setState(() => _eyeLaterality = 'OS'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Device Manufacturer
                            Text(l10n.acquisitionDevice, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _deviceManufacturer,
                              items: const [
                                DropdownMenuItem(value: 'Heidelberg Spectralis OCT', child: Text('Heidelberg Spectralis OCT')),
                                DropdownMenuItem(value: 'Zeiss Cirrus HD-OCT', child: Text('Zeiss Cirrus HD-OCT')),
                                DropdownMenuItem(value: 'Topcon 3D OCT-2000', child: Text('Topcon 3D OCT-2000')),
                                DropdownMenuItem(value: 'Optovue RTVue XR Avanti', child: Text('Optovue RTVue XR Avanti')),
                                DropdownMenuItem(value: 'Generic B-Scan Compatible', child: Text('Generic B-Scan Compatible')),
                              ],
                              onChanged: (v) => setState(() => _deviceManufacturer = v!),
                            ),
                            const SizedBox(height: 16),

                            // Axial Calibration
                            Text(l10n.axialCalibration, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 6),
                            TextFormField(
                              initialValue: '3.87',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                suffixText: 'μm/px',
                                hintText: '3.87',
                              ),
                              onChanged: (v) => _axialCalibrationUm = double.tryParse(v) ?? 3.87,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (isWide) const SizedBox(width: 20) else const SizedBox(height: 20),

                    // Right Column: Upload Box & Validation Analysis
                    Expanded(
                      flex: isWide ? 6 : 0,
                      child: ClinicalCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '2. ${l10n.selectImage}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 16),

                            if (_selectedFileBytes == null)
                              // Drag & Drop / File Picker Area
                              InkWell(
                                onTap: _pickFile,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  height: 230,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF192734) : AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withOpacity(0.4),
                                      style: BorderStyle.solid,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.cloud_upload_outlined, size: 36, color: theme.colorScheme.primary),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        l10n.selectImage,
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.supportedFormats,
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              // Image Selected Preview & Validation Status
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 220,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        _selectedFileBytes!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedFileName ?? 'OCT Image',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _pickFile,
                                        icon: const Icon(Icons.refresh, size: 16),
                                        label: Text(l10n.replace),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Validation Analysis Output
                                  if (_isValidating)
                                    Row(
                                      children: [
                                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                        const SizedBox(width: 10),
                                        Text(l10n.validateImage, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                                      ],
                                    )
                                  else if (_validationResult != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _validationResult!['is_valid_oct'] == true
                                            ? (isDark ? const Color(0xFF064E3B) : AppColors.successLight)
                                            : (isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _validationResult!['is_valid_oct'] == true ? Icons.check_circle : Icons.cancel,
                                            color: _validationResult!['is_valid_oct'] == true
                                                ? (isDark ? const Color(0xFF34D399) : AppColors.success)
                                                : (isDark ? const Color(0xFFF87171) : AppColors.error),
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _validationResult!['is_valid_oct'] == true
                                                      ? l10n.validOCTDetected
                                                      : l10n.invalidOCTDetected,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: _validationResult!['is_valid_oct'] == true
                                                        ? (isDark ? const Color(0xFF34D399) : AppColors.success)
                                                        : (isDark ? const Color(0xFFF87171) : AppColors.error),
                                                  ),
                                                ),
                                                Text(
                                                  _validationResult!['message'] ?? '',
                                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                            const SizedBox(height: 20),

                            // Sample Scans Selector
                            Text(
                              l10n.sampleScans,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: AppConstants.sampleScans.map((sample) {
                                return ActionChip(
                                  avatar: const Icon(Icons.science_outlined, size: 14),
                                  label: Text(sample['name']!, style: const TextStyle(fontSize: 11)),
                                  onPressed: () => _loadSample(sample['id']!),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 24),
                            // Launch AI Pipeline Button
                            ElevatedButton.icon(
                              onPressed: (_isUploading || _isValidating || _selectedFileBytes == null)
                                  ? null
                                  : _startAnalysisPipeline,
                              icon: _isUploading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.auto_awesome),
                              label: Text(
                                _isUploading ? l10n.processing : l10n.startSegmentationBtn,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          ],
                        ),
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
}
