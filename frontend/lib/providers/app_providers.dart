import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/oct_scan_model.dart';
import '../models/segmentation_result_model.dart';
import '../services/app_services.dart';

// Services
final authServiceProvider = Provider((ref) => AuthService());
final patientServiceProvider = Provider((ref) => PatientService());
final octServiceProvider = Provider((ref) => OCTService());
final analysisServiceProvider = Provider((ref) => AnalysisService());
final reportServiceProvider = Provider((ref) => ReportService());
final adminServiceProvider = Provider((ref) => AdminService());

// Auth State
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({this.user, this.isLoading = false, this.errorMessage});

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(AuthState());

  Future<void> checkCurrentUser() async {
    state = AuthState(isLoading: true);
    final user = await _authService.getCurrentUser();
    if (user == null) {
      await _authService.logout();
      state = AuthState(user: null, isLoading: false);
    } else {
      state = AuthState(user: user, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      final user = await _authService.login(email, password);
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(patientsListProvider);
      _ref.invalidate(analysisHistoryProvider);
      _ref.invalidate(selectedPatientProvider);
      _ref.invalidate(currentScanProvider);
      _ref.invalidate(currentSegmentationProvider);
      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? specialty,
    String? licenseNumber,
  }) async {
    state = AuthState(isLoading: true);
    try {
      final user = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        specialty: specialty,
        licenseNumber: licenseNumber,
      );
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(patientsListProvider);
      _ref.invalidate(analysisHistoryProvider);
      _ref.invalidate(selectedPatientProvider);
      _ref.invalidate(currentScanProvider);
      _ref.invalidate(currentSegmentationProvider);
      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(patientsListProvider);
    _ref.invalidate(analysisHistoryProvider);
    _ref.invalidate(selectedPatientProvider);
    _ref.invalidate(currentScanProvider);
    _ref.invalidate(currentSegmentationProvider);
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider), ref);
});

// Patients Provider
final patientsListProvider = FutureProvider.autoDispose<List<PatientModel>>((ref) async {
  final service = ref.watch(patientServiceProvider);
  return await service.getPatients();
});

final selectedPatientProvider = StateProvider<PatientModel?>((ref) => null);

// OCT Upload & Analysis Workflow Providers
final currentScanProvider = StateProvider<OCTScanModel?>((ref) => null);
final currentPreprocessingProvider = StateProvider<PreprocessingModel?>((ref) => null);
final currentSegmentationProvider = StateProvider<SegmentationResultModel?>((ref) => null);

// View Mode Enum (Original, Preprocessed, Segmentation Mask, Overlay)
enum OCTViewMode { original, preprocessed, segmentation, overlay }
final octViewModeProvider = StateProvider<OCTViewMode>((ref) => OCTViewMode.overlay);

// Layer Visibility Toggles (8 Retinal Layers)
final layerVisibilityProvider = StateProvider<Map<String, bool>>((ref) => {
  'ILM': true,
  'RNFL': true,
  'GCL': true,
  'IPL': true,
  'INL': true,
  'OPL': true,
  'ONL': true,
  'RPE': true,
});

// Overlay Opacity (0.0 to 1.0)
final overlayOpacityProvider = StateProvider<double>((ref) => 0.55);

// Dashboard Stats Provider
final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final service = ref.watch(analysisServiceProvider);
  return await service.getDashboardStats();
});

// Analysis History Provider
final analysisHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(analysisServiceProvider);
  return await service.getAnalysisHistory();
});

// Admin Users Provider
final adminUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return await service.getAdminUsers();
});
