import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseStorage get storage => FirebaseStorage.instanceFor(
        bucket: 'oct-medical-application.firebasestorage.app',
      );
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('Firebase initialized successfully for oct-medical-application');
    } catch (e) {
      debugPrint('Firebase initialization warning: $e');
    }
  }

  /// Uploads an OCT B-Scan or PDF report to Firebase Cloud Storage
  Future<String?> uploadFileToFirebaseStorage({
    required String path,
    required Uint8List bytes,
    String contentType = 'image/png',
  }) async {
    if (!_initialized) await initialize();
    try {
      final ref = storage.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage upload error: $e');
      return null;
    }
  }

  /// Logs clinical scan audit metadata to Cloud Firestore
  Future<void> logScanToFirestore({
    required String patientId,
    required String scanUid,
    required String laterality,
    required double confidence,
    required Map<String, dynamic> measurements,
  }) async {
    if (!_initialized) await initialize();
    try {
      await firestore.collection('oct_scans').doc(scanUid).set({
        'patient_id': patientId,
        'scan_uid': scanUid,
        'laterality': laterality,
        'confidence': confidence,
        'measurements': measurements,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore logging error: $e');
    }
  }

  /// Syncs patient profile to Cloud Firestore
  Future<void> syncPatientToFirestore(Map<String, dynamic> patientData) async {
    if (!_initialized) await initialize();
    try {
      final pid = patientData['patient_id']?.toString() ?? 'P_${DateTime.now().millisecondsSinceEpoch}';
      await firestore.collection('patients').doc(pid).set({
        ...patientData,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore patient sync error: $e');
    }
  }

  /// Syncs completed segmentation report to Cloud Firestore
  Future<void> syncReportToFirestore(Map<String, dynamic> reportData) async {
    if (!_initialized) await initialize();
    try {
      final ruid = reportData['report_uid']?.toString() ?? 'REP_${DateTime.now().millisecondsSinceEpoch}';
      await firestore.collection('reports').doc(ruid).set({
        ...reportData,
        'generated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore report sync error: $e');
    }
  }
}
