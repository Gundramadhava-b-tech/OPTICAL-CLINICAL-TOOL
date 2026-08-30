import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_typography.dart';
import '../providers/app_providers.dart';
import '../providers/settings_provider.dart';
import '../widgets/clinical_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settings,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.appearance}, ${l10n.language}, ${l10n.profile} & ${l10n.regulatoryDisclaimer}',
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 1. APPEARANCE (THEME SWITCHER)
              // ==========================================
              ClinicalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.appearance,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.theme,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildThemeOption(
                              context: context,
                              icon: Icons.light_mode_outlined,
                              label: l10n.lightTheme,
                              isSelected: settings.themeMode == ThemeMode.light,
                              onTap: () => ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.light),
                            ),
                            _buildThemeOption(
                              context: context,
                              icon: Icons.dark_mode_outlined,
                              label: l10n.darkTheme,
                              isSelected: settings.themeMode == ThemeMode.dark,
                              onTap: () => ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark),
                            ),
                            _buildThemeOption(
                              context: context,
                              icon: Icons.settings_brightness_outlined,
                              label: l10n.systemTheme,
                              isSelected: settings.themeMode == ThemeMode.system,
                              onTap: () => ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.system),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 2. LANGUAGE SELECTOR (EN, TE, HI, TA)
              // ==========================================
              ClinicalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.translate, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.language,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Select Interface Language',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildLanguageOption(
                          context: context,
                          code: 'en',
                          title: 'English',
                          sub: 'English',
                          isSelected: settings.locale.languageCode == 'en',
                          onTap: () => ref.read(settingsProvider.notifier).setLocale(const Locale('en')),
                        ),
                        _buildLanguageOption(
                          context: context,
                          code: 'te',
                          title: 'తెలుగు',
                          sub: 'Telugu',
                          isSelected: settings.locale.languageCode == 'te',
                          onTap: () => ref.read(settingsProvider.notifier).setLocale(const Locale('te')),
                        ),
                        _buildLanguageOption(
                          context: context,
                          code: 'hi',
                          title: 'हिन्दी',
                          sub: 'Hindi',
                          isSelected: settings.locale.languageCode == 'hi',
                          onTap: () => ref.read(settingsProvider.notifier).setLocale(const Locale('hi')),
                        ),
                        _buildLanguageOption(
                          context: context,
                          code: 'ta',
                          title: 'தமிழ்',
                          sub: 'Tamil',
                          isSelected: settings.locale.languageCode == 'ta',
                          onTap: () => ref.read(settingsProvider.notifier).setLocale(const Locale('ta')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Live Language & Font Preview Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TYPOGRAPHY & FONT PREVIEW',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  AppTypography.getFontFamilyName(settings.locale),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppTypography.getFontPreviewText(settings.locale),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Anatomical layers: ILM, RNFL, GCL, IPL, INL, OPL, ONL, RPE (250 μm • 94% confidence)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 3. SPECIALIST PROFILE CARD
              // ==========================================
              ClinicalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'D',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Dr. Sarah Reynolds, MD',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${user?.role ?? l10n.ophthalmologistRole} • ${user?.specialty ?? "Retina Specialist"}',
                                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                user?.email ?? 'doctor@retinaseg.ai',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 4. AI MODEL INFORMATION CARD
              // ==========================================
              ClinicalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.memory, color: Theme.of(context).colorScheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'System & AI Model Configuration',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Inference engine specifications and optical calibration standards',
                                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF064E3B) : AppColors.successLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Engine v2.4 Active',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Grid-like tiles
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 600;
                        return Column(
                          children: [
                            // Row 1: Model Architecture & Retinal Layers
                            if (isNarrow) ...[
                              _buildSpecTile(
                                context: context,
                                icon: Icons.psychology_outlined,
                                label: 'Model Architecture',
                                title: 'U-Net 4-Depth Residual',
                                description: 'Deep convolutional network with residual skip blocks and Squeeze-and-Excitation channel attention.',
                                tags: const ['SE-Attention', 'Residual Skips', '512×512 Tensor'],
                              ),
                              const SizedBox(height: 12),
                              _buildLayersTile(context),
                            ] else ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildSpecTile(
                                      context: context,
                                      icon: Icons.psychology_outlined,
                                      label: 'Model Architecture',
                                      title: 'U-Net 4-Depth Residual',
                                      description: 'Deep convolutional network with residual skip blocks and Squeeze-and-Excitation attention.',
                                      tags: const ['SE-Attention', 'Residual Skips', '512×512 Tensor'],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildLayersTile(context),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),

                            // Row 2: Preprocessing Pipeline (Full Width)
                            _buildPipelineTile(context),
                            const SizedBox(height: 14),

                            // Row 3: Axial Resolution & Database Backend
                            if (isNarrow) ...[
                              _buildSpecTile(
                                context: context,
                                icon: Icons.straighten_outlined,
                                label: 'Axial Resolution Standard',
                                title: '3.87 µm / pixel',
                                description: 'Physical micrometer scale standardized for Heidelberg Spectralis & Zeiss Cirrus HD-OCT.',
                                badgeText: 'Standardized Ophthalmic Metric',
                              ),
                              const SizedBox(height: 12),
                              _buildSpecTile(
                                context: context,
                                icon: Icons.local_fire_department_outlined,
                                label: 'Database Backend',
                                title: 'Firebase Cloud Firestore',
                                description: 'Cloud NoSQL document database with automated real-time sync and clinical cloud storage.',
                                tags: const ['Realtime Sync', 'Cloud Storage', 'oct-medical-application'],
                              ),
                            ] else ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildSpecTile(
                                      context: context,
                                      icon: Icons.straighten_outlined,
                                      label: 'Axial Resolution Standard',
                                      title: '3.87 µm / pixel',
                                      description: 'Physical micrometer scale standardized for Heidelberg Spectralis & Zeiss Cirrus HD-OCT.',
                                      badgeText: 'Standardized Ophthalmic Metric',
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildSpecTile(
                                      context: context,
                                      icon: Icons.local_fire_department_outlined,
                                      label: 'Database Backend',
                                      title: 'Firebase Cloud Firestore',
                                      description: 'Cloud NoSQL document database with automated real-time sync and clinical cloud storage.',
                                      tags: const ['Realtime Sync', 'Cloud Storage', 'oct-medical-application'],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 5. REGULATORY DISCLAIMER
              // ==========================================
              ClinicalCard(
                backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.primarySurface,
                borderColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.regulatoryDisclaimer,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.clinicalDisclaimer,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.12) : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String code,
    required String title,
    required String sub,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.12) : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? theme.colorScheme.primary.withOpacity(0.8) : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String title,
    required String description,
    List<String>? tags,
    String? badgeText,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.35 : 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (tags != null && tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (badgeText != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C4A6E) : AppColors.infoLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 12, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLayersTile(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const layers = ['ILM', 'RNFL', 'GCL', 'IPL', 'INL', 'OPL', 'ONL', 'RPE'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.35 : 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.layers_outlined, size: 16, color: AppColors.secondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SUPPORTED LAYERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '8 Anatomical Retinal Layers',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Full microstructural boundary segmentation across all clinical sub-retinal layers.',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: layers.map((layer) {
              final color = AppColors.getLayerColor(layer);
              final isBright = layer == 'GCL';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  layer,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isBright ? const Color(0xFF1E293B) : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineTile(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.35 : 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.tune_outlined, size: 16, color: AppColors.warning),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PREPROCESSING PIPELINE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enhanced Optical Contrast & Denoising',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWrap = constraints.maxWidth < 650;
              final steps = [
                _buildStepItem(context, '1', 'Grayscale', 'Luminance Conv'),
                _buildStepItem(context, '2', 'Bilateral Filter', 'Speckle Denoising'),
                _buildStepItem(context, '3', 'CLAHE', 'Adaptive Hist (2.0)'),
                _buildStepItem(context, '4', 'Min-Max Norm', '[0.0, 1.0] Range'),
              ];

              if (isWrap) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: steps,
                );
              }

              return Row(
                children: [
                  Expanded(child: steps[0]),
                  Icon(Icons.arrow_forward, size: 14, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  Expanded(child: steps[1]),
                  Icon(Icons.arrow_forward, size: 14, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  Expanded(child: steps[2]),
                  Icon(Icons.arrow_forward, size: 14, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  Expanded(child: steps[3]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, String num, String title, String sub) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              num,
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub,
                  style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
