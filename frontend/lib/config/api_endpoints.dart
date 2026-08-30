import 'package:flutter/foundation.dart';

class AppConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  static const String apiPrefix = '/api';
  
  static String get fullApiUrl => '$baseUrl$apiPrefix';
}

class ApiEndpoints {
  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Patients
  static const String patients = '/patients';
  static String patientDetails(int id) => '/patients/$id';

  // OCT
  static const String octUpload = '/oct/upload';
  static const String octValidate = '/oct/validate-only';
  static String octDetails(int id) => '/oct/$id';

  // Analysis
  static const String preprocess = '/analysis/preprocess';
  static const String segment = '/analysis/segment';
  static String analysisResult(int id) => '/analysis/$id';
  static const String analysisHistory = '/analysis/history/all';

  // Reports
  static const String generateReport = '/reports/generate';
  static String downloadReport(int id) => '/reports/download/$id';

  // Dashboard & Admin
  static const String dashboardStats = '/dashboard/stats';
  static const String adminUsers = '/admin/users';
  static const String adminModels = '/admin/models';
  static const String adminAuditLogs = '/admin/audit-logs';
}
