import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AnalysisStepperWidget extends StatelessWidget {
  final int currentStep; // 1 to 6
  final String statusMessage;

  const AnalysisStepperWidget({
    super.key,
    required this.currentStep,
    required this.statusMessage,
  });

  static const List<String> stepTitles = [
    'OCT Upload',
    'Image Validation',
    'CLAHE Preprocessing',
    'U-Net Segmentation',
    'Thickness Measurements',
    'Results Ready',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Pipeline Execution Status',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          // Horizontal / Vertical steps
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: List.generate(stepTitles.length, (idx) {
                    final stepNum = idx + 1;
                    final isDone = stepNum < currentStep;
                    final isCurrent = stepNum == currentStep;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          _buildStepCircle(stepNum, isDone, isCurrent),
                          const SizedBox(width: 10),
                          Text(
                            stepTitles[idx],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isDone || isCurrent ? AppColors.textPrimary : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                );
              }

              return Row(
                children: List.generate(stepTitles.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    final stepBefore = (index ~/ 2) + 1;
                    final isPassed = stepBefore < currentStep;
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: isPassed ? AppColors.primary : AppColors.divider,
                      ),
                    );
                  }

                  final stepNum = (index ~/ 2) + 1;
                  final isDone = stepNum < currentStep;
                  final isCurrent = stepNum == currentStep;

                  return Column(
                    children: [
                      _buildStepCircle(stepNum, isDone, isCurrent),
                      const SizedBox(height: 6),
                      Text(
                        stepTitles[stepNum - 1],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isDone || isCurrent ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepNum, bool isDone, bool isCurrent) {
    if (isDone) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    } else if (isCurrent) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$stepNum',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            '$stepNum',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      );
    }
  }
}
