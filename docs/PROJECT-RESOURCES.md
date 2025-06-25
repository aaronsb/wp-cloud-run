# Project Resources & Credentials

> ⚠️ **CONFIDENTIAL**: This file contains sensitive information. Never commit actual passwords.

## Google Cloud Resources

### Project Information
- **Project ID**: `wordpress-bockelie`
- **Project Number**: `36366010430`
- **Billing Account**: `00FF9A-009D32-54C463`
- **Region**: `us-central1`

### Cloud Run
- **Service Name**: `wp-cloud-run`
- **URL**: https://wp-cloud-run-36366010430.us-central1.run.app
- **Custom Domain**: https://graph-attract.io
- **Container Registry**: `us-central1-docker.pkg.dev/wordpress-bockelie/cloud-run-source-deploy/wp-cloud-run`

### Cloud SQL
- **Instance Name**: `wordpress-db`
- **Connection Name**: `wordpress-bockelie:us-central1:wordpress-db`
- **Database Name**: `wordpress`
- **Username**: `wordpress`
- **Password**: Stored in Secret Manager as `wordpress-db-password`
- **IP Address**: `34.42.176.229`

### Cloud Storage
- **Media Bucket**: `wordpress-bockelie-wordpress-media`
- **Public URL**: https://storage.googleapis.com/wordpress-bockelie-wordpress-media/
- **Service Account**: `wordpress-gcs-sa@wordpress-bockelie.iam.gserviceaccount.com`

### Service Accounts
1. **WordPress App SA**: `wordpress-sa@wordpress-bockelie.iam.gserviceaccount.com`
   - Roles: Cloud SQL Client, Secret Manager Accessor, Logging Writer

2. **GCS Media SA**: `wordpress-gcs-sa@wordpress-bockelie.iam.gserviceaccount.com`
   - Roles: Storage Admin, Storage Object Admin

### Secrets in Secret Manager
- `wordpress-db-password`
- `wordpress-auth-key`
- `wordpress-secure-auth-key`
- `wordpress-logged-in-key`
- `wordpress-nonce-key`
- `wordpress-auth-salt`
- `wordpress-secure-auth-salt`
- `wordpress-logged-in-salt`
- `wordpress-nonce-salt`

### GitHub Integration
- **Repository**: https://github.com/aaronsb/wp-cloud-run
- **Build Trigger**: Auto-deploys on push to `main`
- **Build Config**: `/cloudbuild.yaml`

### Domain Configuration
- **Primary Domain**: `graph-attract.io`
- **WWW Domain**: `www.graph-attract.io`
- **DNS Records**: 
  - 4 A records pointing to Google IPs
  - CNAME for www → `ghs.googlehosted.com`
  - TXT record for domain verification

### Local Development
- **Docker Compose**: Available for local testing
- **Environment File**: `.env` (git-ignored)
- **GCS Key File**: `wordpress-gcs-key.json` (git-ignored)

## Access Management

### WordPress Admin
- **URL**: https://graph-attract.io/wp-admin
- **Username**: [Configured during setup]
- **Password**: [Configured during setup]

### Google Cloud Access
- **Primary Account**: aaronsb@gmail.com
- **Role**: Project Owner
- **Console**: https://console.cloud.google.com/home/dashboard?project=wordpress-bockelie

### Emergency Contacts
- **Billing Alerts**: Sent to account email
- **Domain Registrar**: [Your registrar for graph-attract.io]

## Cost Management

### Budget Alert Configuration
- **Budget ID**: `dab3b11e-13d4-41d3-8c3a-0490bc93b532`
- **Monthly Budget**: $50 USD
- **Alert Thresholds**:
  - 50% ($25) - Early warning
  - 80% ($40) - Approaching limit
  - 90% ($45) - Critical warning
  - 100% ($50) - Budget reached
- **Created**: June 25, 2025
- **Email Notifications**: Sent to account owner

### Current Resource Limits
- **Max Instances**: 2
- **Memory per Instance**: 256MB
- **Concurrent Requests**: 10 per instance
- **Cloud SQL Tier**: db-g1-small ($25.55/month)

### Monitoring
- **Billing Dashboard**: https://console.cloud.google.com/billing
- **Cloud Run Metrics**: https://console.cloud.google.com/run
- **Cloud SQL Metrics**: https://console.cloud.google.com/sql

## Recovery Information

### Backups
- **Database**: Automatic daily backups, 7-day retention
- **Media Files**: Stored in GCS (inherently durable)
- **Code**: Version controlled in GitHub

### Legacy Resources
- **Old Disk Image**: `wordpress-disk-2022.img.gz` (March 2022 backup)
- **Old Project**: `bitnami-brwgrbbowg` (do not use)

---

*Last Updated: June 25, 2025*