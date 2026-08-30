# RetinaSeg AI – Firebase Architecture & Configuration
**Project ID**: `oct-medical-application`  
**Storage Bucket**: `oct-medical-application.firebasestorage.app`

---

## Folder Structure

```
firebase/
├── google-services.json    # Android configuration (Package: com.example.oct_retinal_segmentation)
├── firebase_config.js      # Web SDK configuration (Measurement ID: G-7JSRW5LTSZ)
├── firebase_options.dart   # Flutter cross-platform Dart options
├── firestore.rules         # Cloud Firestore security rules
├── storage.rules           # Cloud Storage security rules for OCT rasters & PDF reports
├── fingerprints.json       # SHA-1, SHA-256, and MD5 certificate fingerprints
└── README.md               # Firebase documentation
```

---

## Key Credentials Summary

### 1. Android Client
- **App ID**: `1:460488188037:android:16993da53b8656aefd89ec`
- **Package Name**: `com.example.oct_retinal_segmentation`
- **SHA-1 Fingerprint**: `AA:77:6D:08:7B:41:A7:F8:01:49:68:9D:4D:15:9D:FF:54:B3:5D:DF`
- **SHA-256 Fingerprint**: `58:4A:24:8B:1F:8F:44:08:AB:8C:BE:46:EF:F6:DC:AD:86:CD:64:5B:34:C2:37:AB:5E:EC:9F:23:59:D8:D1:DB`

### 2. Web Client
- **App ID**: `1:460488188037:web:d90ffb9e3b841df9fd89ec`
- **API Key**: `AIzaSyCmwLn2DZYXbMm9agSIjpdqZCheNflv67g`
- **Measurement ID**: `G-7JSRW5LTSZ`
- **Auth Domain**: `oct-medical-application.firebaseapp.com`

---

## Deployment with Firebase CLI
To deploy the Web frontend and security rules to Firebase:
```bash
firebase deploy
```
