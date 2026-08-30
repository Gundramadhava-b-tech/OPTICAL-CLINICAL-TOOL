"""
RetinaSeg AI - Data Models
Note: Relational SQLAlchemy models (db_models.py) have been removed.
All documents are managed in Google Firebase Cloud Firestore collections:
- `users`
- `patients`
- `oct_scans`
- `analysis_results`
- `reports`
- `audit_logs`
Schemas are validated via Pydantic in `backend.schemas.api_schemas`.
"""
