import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_endpoints.dart';
import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/oct_scan_model.dart';
import '../models/segmentation_result_model.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<UserModel?> getCurrentUser() async {
    try {
      final res = await _client.dio.get(ApiEndpoints.me);
      return UserModel.fromJson(res.data);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.login,
        data: {'email': email.trim().toLowerCase(), 'password': password},
      );
      final token = res.data['access_token'] as String;
      final user = UserModel.fromJson(res.data['user']);
      await _client.saveToken(token);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Invalid email or password.';
      throw Exception(msg);
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? specialty,
    String? licenseNumber,
  }) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.register,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
          'full_name': fullName.trim(),
          'role': role,
          'specialty': specialty,
          'license_number': licenseNumber,
        },
      );
      if (res.data is Map<String, dynamic> && res.data.containsKey('access_token')) {
        final token = res.data['access_token'] as String;
        final user = UserModel.fromJson(res.data['user']);
        await _client.saveToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(user.toJson()));
        return user;
      }
      return UserModel.fromJson(res.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Registration failed.';
      throw Exception(msg);
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post(ApiEndpoints.logout);
    } catch (_) {}
    await _client.clearToken();
  }
}

class PatientService {
  final ApiClient _client = ApiClient();

  Future<List<PatientModel>> getPatients({String? search, String? gender}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (gender != null && gender.isNotEmpty) queryParams['gender'] = gender;

    final res = await _client.dio.get(ApiEndpoints.patients, queryParameters: queryParams);
    return (res.data as List).map((e) => PatientModel.fromJson(e)).toList();
  }

  Future<PatientModel> getPatient(int id) async {
    final res = await _client.dio.get(ApiEndpoints.patientDetails(id));
    return PatientModel.fromJson(res.data);
  }

  Future<PatientModel> createPatient(Map<String, dynamic> data) async {
    try {
      final res = await _client.dio.post(ApiEndpoints.patients, data: data);
      return PatientModel.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to create patient.');
    }
  }

  Future<PatientModel> updatePatient(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.put(ApiEndpoints.patientDetails(id), data: data);
    return PatientModel.fromJson(res.data);
  }

  Future<void> deletePatient(int id) async {
    await _client.dio.delete(ApiEndpoints.patientDetails(id));
  }
}

class OCTService {
  final ApiClient _client = ApiClient();

  Future<OCTScanModel> uploadOCTScan({
    required int patientId,
    required String eyeLaterality,
    required String deviceManufacturer,
    required double axialResolutionUm,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'patient_id': patientId,
        'eye_laterality': eyeLaterality,
        'device_manufacturer': deviceManufacturer,
        'axial_resolution_um': axialResolutionUm,
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final res = await _client.dio.post(ApiEndpoints.octUpload, data: formData);
      return OCTScanModel.fromJson(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final err = e.response?.data?['detail'];
        if (err is Map && err.containsKey('message')) {
          throw Exception(err['message']);
        }
      }
      throw Exception(e.response?.data?['detail'] ?? 'Failed to upload OCT scan.');
    }
  }

  Future<Map<String, dynamic>> validateScanOnly(List<int> fileBytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final res = await _client.dio.post(ApiEndpoints.octValidate, data: formData);
    return res.data as Map<String, dynamic>;
  }

  Future<OCTScanModel> getScanDetails(int id) async {
    final res = await _client.dio.get(ApiEndpoints.octDetails(id));
    return OCTScanModel.fromJson(res.data);
  }
}

class AnalysisService {
  final ApiClient _client = ApiClient();

  Future<PreprocessingModel> runPreprocessing(int scanId, {double clipLimit = 2.5}) async {
    final res = await _client.dio.post(
      ApiEndpoints.preprocess,
      data: {
        'scan_id': scanId,
        'apply_bilateral_filter': true,
        'apply_clahe': true,
        'clahe_clip_limit': clipLimit,
        'normalize_intensity': true,
      },
    );
    return PreprocessingModel.fromJson(res.data);
  }

  Future<SegmentationResultModel> runSegmentation(int scanId, {double confidenceThreshold = 0.5}) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.segment,
        data: {
          'scan_id': scanId,
          'confidence_threshold': confidenceThreshold,
          'include_boundary_data': true,
        },
      );
      return SegmentationResultModel.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'U-Net segmentation failed.');
    }
  }

  Future<SegmentationResultModel> getAnalysisResult(int id) async {
    final res = await _client.dio.get(ApiEndpoints.analysisResult(id));
    return SegmentationResultModel.fromJson(res.data);
  }

  Future<List<Map<String, dynamic>>> getAnalysisHistory({int? patientId, String? search}) async {
    final q = <String, dynamic>{};
    if (patientId != null) q['patient_id'] = patientId;
    if (search != null && search.isNotEmpty) q['search'] = search;
    
    final res = await _client.dio.get(ApiEndpoints.analysisHistory, queryParameters: q);
    return (res.data as List).map((e) => e as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await _client.dio.get(ApiEndpoints.dashboardStats);
    return res.data as Map<String, dynamic>;
  }
}

class ReportService {
  final ApiClient _client = ApiClient();

  Future<ReportModel> generateReport(int analysisId, {String? notes}) async {
    final res = await _client.dio.post(
      ApiEndpoints.generateReport,
      data: {
        'analysis_id': analysisId,
        'notes': notes,
        'include_preprocessed': true,
        'include_measurements_table': true,
      },
    );
    return ReportModel.fromJson(res.data);
  }
}

class AdminService {
  final ApiClient _client = ApiClient();

  Future<List<UserModel>> getAdminUsers() async {
    final res = await _client.dio.get(ApiEndpoints.adminUsers);
    return (res.data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> toggleUserStatus(int userId, bool isActive) async {
    await _client.dio.put(
      '/admin/users/$userId/status',
      queryParameters: {'is_active': isActive},
    );
  }
}
