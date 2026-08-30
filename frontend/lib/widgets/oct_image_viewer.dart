import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../config/app_config.dart';
import '../providers/app_providers.dart';

class OCTImageViewer extends ConsumerStatefulWidget {
  final String originalImageUrl;
  final String? preprocessedImageUrl;
  final String? maskImageUrl;
  final String? overlayImageUrl;
  final double height;

  const OCTImageViewer({
    super.key,
    required this.originalImageUrl,
    this.preprocessedImageUrl,
    this.maskImageUrl,
    this.overlayImageUrl,
    this.height = 420,
  });

  @override
  ConsumerState<OCTImageViewer> createState() => _OCTImageViewerState();
}

class _OCTImageViewerState extends ConsumerState<OCTImageViewer> {
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  void _zoomIn() {
    setState(() {
      _currentScale = (_currentScale * 1.25).clamp(0.5, 5.0);
      _transformationController.value = Matrix4.diagonal3Values(_currentScale, _currentScale, 1.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale = (_currentScale / 1.25).clamp(0.5, 5.0);
      _transformationController.value = Matrix4.diagonal3Values(_currentScale, _currentScale, 1.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _currentScale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  String _resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${AppConfig.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final viewMode = ref.watch(octViewModeProvider);

    String activeUrl = widget.originalImageUrl;
    if (viewMode == OCTViewMode.preprocessed && widget.preprocessedImageUrl != null) {
      activeUrl = widget.preprocessedImageUrl!;
    } else if (viewMode == OCTViewMode.segmentation && widget.maskImageUrl != null) {
      activeUrl = widget.maskImageUrl!;
    } else if (viewMode == OCTViewMode.overlay && widget.overlayImageUrl != null) {
      activeUrl = widget.overlayImageUrl!;
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        // High contrast medical dark viewport background for accurate pixel perception
        color: const Color(0xFF0A1118),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          // Interactive Pan & Zoom Canvas - Unfiltered Medical OCT Pixels
          Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 5.0,
              boundaryMargin: const EdgeInsets.all(40),
              onInteractionUpdate: (details) {
                setState(() {
                  _currentScale = _transformationController.value.getMaxScaleOnAxis();
                });
              },
              child: Image.network(
                _resolveImageUrl(activeUrl),
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryLight),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Unable to load scan raster',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // View Mode Selector Toolbar (Top Left)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  _buildViewTab(OCTViewMode.original, l10n.original, viewMode),
                  if (widget.preprocessedImageUrl != null)
                    _buildViewTab(OCTViewMode.preprocessed, l10n.preprocessed, viewMode),
                  if (widget.maskImageUrl != null)
                    _buildViewTab(OCTViewMode.segmentation, l10n.segmentationMask, viewMode),
                  if (widget.overlayImageUrl != null)
                    _buildViewTab(OCTViewMode.overlay, l10n.overlay, viewMode),
                ],
              ),
            ),
          ),

          // Zoom Controls Toolbar (Bottom Right)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_out, color: Colors.white, size: 18),
                    tooltip: 'Zoom Out',
                    onPressed: _zoomOut,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(_currentScale * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                    tooltip: 'Zoom In',
                    onPressed: _zoomIn,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.restart_alt, color: Colors.white, size: 18),
                    tooltip: l10n.reset,
                    onPressed: _resetZoom,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab(OCTViewMode mode, String label, OCTViewMode currentMode) {
    final isSelected = currentMode == mode;
    return InkWell(
      onTap: () => ref.read(octViewModeProvider.notifier).state = mode,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
