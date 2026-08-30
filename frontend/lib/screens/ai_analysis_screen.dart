import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../models/oct_scan_model.dart';
import '../providers/app_providers.dart';
import '../widgets/clinical_card.dart';
import '../widgets/analysis_stepper_widget.dart';
import 'segmentation_workspace_screen.dart';

class AIAnalysisScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;

  const AIAnalysisScreen({super.key, this.onNavigate});

  @override
  ConsumerState<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends ConsumerState<AIAnalysisScreen> {
  int _currentStep = 1;
  String _statusMessage = 'Initializing analysis pipeline...';
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysisPipeline();
    });
  }

  void _startAnalysisPipeline() async {
    final l10n = AppLocalizations.of(context);
    final scan = ref.read(currentScanProvider);
    if (scan == null) {
      setState(() {
        _error = l10n.validOCTRequired;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStep = 2;
      _statusMessage = l10n.step2Validation;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Step 3: Run CLAHE & Bilateral Preprocessing
      setState(() {
        _currentStep = 3;
        _statusMessage = l10n.step3CLAHE;
      });

      final prepRes = await ref.read(analysisServiceProvider).runPreprocessing(scan.id);
      ref.read(currentPreprocessingProvider.notifier).state = prepRes;

      await Future.delayed(const Duration(milliseconds: 700));

      // Step 4: Run U-Net Multi-Layer Segmentation
      setState(() {
        _currentStep = 4;
        _statusMessage = l10n.step4UNet;
      });

      final segRes = await ref.read(analysisServiceProvider).runSegmentation(scan.id);
      ref.read(currentSegmentationProvider.notifier).state = segRes;
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(analysisHistoryProvider);

      await Future.delayed(const Duration(milliseconds: 600));

      // Step 5: Extract Measurements
      setState(() {
        _currentStep = 5;
        _statusMessage = l10n.step5Thickness;
      });

      await Future.delayed(const Duration(milliseconds: 600));

      // Step 6: Completed
      setState(() {
        _currentStep = 6;
        _statusMessage = l10n.step6Workspace;
        _isProcessing = false;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SegmentationWorkspaceScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scan = ref.watch(currentScanProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_error != null)
                  ClinicalCard(
                    backgroundColor: isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight,
                    borderColor: AppColors.error.withOpacity(0.3),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          l10n.failed,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (widget.onNavigate != null) {
                              widget.onNavigate!(2); // Return to upload
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Header
                  Text(
                    l10n.segmentation,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scan != null ? 'Scan ID: ${scan.scanUid} • Patient: ${scan.patientName ?? "Patient"}' : l10n.processing,
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),

                  // Progress Stepper Component
                  AnalysisStepperWidget(
                    currentStep: _currentStep,
                    statusMessage: _statusMessage,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
