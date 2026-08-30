import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/responsive_layout.dart';
import 'providers/app_providers.dart';
import 'services/firebase_service.dart';
import 'widgets/desktop_sidebar.dart';
import 'screens/landing_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/upload_oct_screen.dart';
import 'screens/ai_analysis_screen.dart';
import 'screens/segmentation_workspace_screen.dart';
import 'screens/analysis_history_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/admin_users_screen.dart';

import 'core/localization/app_localizations.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for Android & Web
  try {
    await FirebaseService().initialize();
  } catch (e) {
    debugPrint('Firebase startup notice: $e');
  }

  runApp(const ProviderScope(child: RetinaSegApp()));
}

class RetinaSegApp extends ConsumerWidget {
  const RetinaSegApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'RetinaSeg AI – Automated Retinal Layer Segmentation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(settings.locale),
      darkTheme: AppTheme.darkTheme(settings.locale),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const RootNavigationHandler(),
    );
  }
}

class RootNavigationHandler extends ConsumerStatefulWidget {
  const RootNavigationHandler({super.key});

  @override
  ConsumerState<RootNavigationHandler> createState() => _RootNavigationHandlerState();
}

class _RootNavigationHandlerState extends ConsumerState<RootNavigationHandler> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await ref.read(authProvider.notifier).checkCurrentUser();
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      final theme = Theme.of(context);
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      );
    }

    final authState = ref.watch(authProvider);

    if (authState.isAuthenticated) {
      return const MainWorkspaceShell();
    } else {
      return const LandingScreen();
    }
  }
}

class MainWorkspaceShell extends ConsumerStatefulWidget {
  const MainWorkspaceShell({super.key});

  @override
  ConsumerState<MainWorkspaceShell> createState() => _MainWorkspaceShellState();
}

class _MainWorkspaceShellState extends ConsumerState<MainWorkspaceShell> {
  int _selectedIndex = 0;

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(onNavigate: _onNavigate);
      case 1:
        return PatientsScreen(onNavigateToUpload: _onNavigate);
      case 2:
        return UploadOCTScreen(onNavigateToAnalysis: _onNavigate);
      case 3:
        return AIAnalysisScreen(onNavigate: _onNavigate);
      case 4:
        return const AnalysisHistoryScreen();
      case 5:
        return const ReportsScreen();
      case 6:
        return const AdminUsersScreen();
      case 7:
        return const SettingsScreen();
      case 8:
        return const SettingsScreen();
      default:
        return DashboardScreen(onNavigate: _onNavigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      // Mobile / Android layout with bottom navigation bar
      mobile: Scaffold(
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
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                AppConstants.appName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 20, color: AppColors.textSecondary),
              tooltip: 'Logout',
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 4),
          onTap: _onNavigate,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Patients'),
            BottomNavigationBarItem(icon: Icon(Icons.cloud_upload_outlined), label: 'Upload'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      ),

      // Desktop / Web layout with full sidebar
      desktop: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            DesktopSidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onNavigate,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
