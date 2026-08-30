import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Login', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: const Text('Get Started'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primarySurface, AppColors.background],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'CLINICAL OPHTHALMOLOGY AI PLATFORM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Automated Retinal Layer Segmentation in OCT Images',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Advanced optical coherence tomography (OCT) image analysis powered by enhanced CLAHE preprocessing, deep-learning U-Net segmentation, and calibrated quantitative layer thickness extraction.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Start Clinical Analysis'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('Access Workspace'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Features Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    Text(
                      'Key Clinical & Computational Features',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        _buildFeatureCard(
                          icon: Icons.filter_center_focus_outlined,
                          title: 'Automated OCT Analysis',
                          desc: 'Full-stack B-scan processing pipeline from image acquisition to structured diagnostic output.',
                        ),
                        _buildFeatureCard(
                          icon: Icons.layers_outlined,
                          title: '8-Layer Retinal Segmentation',
                          desc: 'Delineates ILM, RNFL, GCL, IPL, INL, OPL, ONL, and RPE with precise pixel-level boundaries.',
                        ),
                        _buildFeatureCard(
                          icon: Icons.tune_outlined,
                          title: 'Enhanced CLAHE Preprocessing',
                          desc: 'Bilateral filtering and contrast-limited adaptive equalization to eliminate optical speckle noise.',
                        ),
                        _buildFeatureCard(
                          icon: Icons.psychology_outlined,
                          title: 'Deep U-Net Neural Network',
                          desc: 'High-resolution feature extraction with multi-scale skip connections for microstructural fidelity.',
                        ),
                        _buildFeatureCard(
                          icon: Icons.straighten_outlined,
                          title: 'Quantitative Thickness Profiles',
                          desc: 'Mean, min, and max layer thicknesses in pixels and calibrated physical micrometers (μm).',
                        ),
                        _buildFeatureCard(
                          icon: Icons.picture_as_pdf_outlined,
                          title: 'Automated Medical PDF Reports',
                          desc: 'Generates comprehensive ophthalmic reports ready for clinical documentation and export.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // How It Works
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              color: AppColors.surface,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      Text(
                        'Clinical Workflow in 6 Steps',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildStepItem('1', 'Upload OCT', 'Import Spectralis, Cirrus, or standard B-scan images.'),
                          _buildStepItem('2', 'Strict Validation', 'Automated rejection of non-OCT images & photos.'),
                          _buildStepItem('3', 'CLAHE Enhancement', 'Speckle noise filtering & contrast optimization.'),
                          _buildStepItem('4', 'U-Net Inference', 'Deep learning pixel mask generation.'),
                          _buildStepItem('5', 'Quantitative Metrics', 'Thickness extraction across all 8 retinal layers.'),
                          _buildStepItem('6', 'Export PDF Report', 'Download signed clinical documentation.'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              color: AppColors.primaryDark,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Version ${AppConstants.appVersion}',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppConstants.clinicalDisclaimer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String desc}) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 14),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildStepItem(String num, String title, String desc) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
