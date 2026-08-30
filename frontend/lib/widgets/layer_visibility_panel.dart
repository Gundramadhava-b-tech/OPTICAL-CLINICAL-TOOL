import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';
import '../providers/app_providers.dart';

class LayerVisibilityPanel extends ConsumerWidget {
  const LayerVisibilityPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final layerVisibility = ref.watch(layerVisibilityProvider);
    final opacity = ref.watch(overlayOpacityProvider);

    return Container(
      padding: const EdgeInsets.all(16),
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
              Row(
                children: [
                  Icon(Icons.layers_outlined, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.layerVisibility,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      final updated = <String, bool>{};
                      for (var l in AppConstants.retinalLayers) {
                        updated[l] = true;
                      }
                      ref.read(layerVisibilityProvider.notifier).state = updated;
                    },
                    child: Text(l10n.showAll, style: const TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () {
                      final updated = <String, bool>{};
                      for (var l in AppConstants.retinalLayers) {
                        updated[l] = false;
                      }
                      ref.read(layerVisibilityProvider.notifier).state = updated;
                    },
                    child: Text(l10n.hideAll, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 16),
          
          // 8 Layer Visibility Checkboxes (Medical abbreviations preserved)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: AppConstants.retinalLayers.map((layer) {
              final isVisible = layerVisibility[layer] ?? true;
              final layerColor = AppColors.getLayerColor(layer);
              final fullName = AppConstants.layerFullNames[layer] ?? layer;

              return FilterChip(
                selected: isVisible,
                label: Row(
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
                    const SizedBox(width: 6),
                    Text(
                      layer,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isVisible ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                tooltip: fullName,
                selectedColor: layerColor.withOpacity(0.18),
                backgroundColor: theme.colorScheme.surfaceVariant,
                side: BorderSide(
                  color: isVisible ? layerColor : theme.colorScheme.outline.withOpacity(0.2),
                  width: isVisible ? 1.5 : 1.0,
                ),
                onSelected: (selected) {
                  final updated = Map<String, bool>.from(layerVisibility);
                  updated[layer] = selected;
                  ref.read(layerVisibilityProvider.notifier).state = updated;
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          // Opacity Slider
          Row(
            children: [
              Text(
                '${l10n.overlayOpacity}:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: opacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  activeColor: theme.colorScheme.primary,
                  label: '${(opacity * 100).toInt()}%',
                  onChanged: (val) {
                    ref.read(overlayOpacityProvider.notifier).state = val;
                  },
                ),
              ),
              Text(
                '${(opacity * 100).toInt()}%',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
