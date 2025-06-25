# Graph-Attract.io WordPress Infrastructure

> WordPress on Google Cloud Run - Fully Managed, Auto-Scaling, Cost-Controlled

## 🚀 Quick Access

- **Production Site**: https://graph-attract.io
- **WordPress Admin**: https://graph-attract.io/wp-admin
- **Cloud Console**: [WordPress Project](https://console.cloud.google.com/home/dashboard?project=wordpress-bockelie)
- **GitHub Repository**: https://github.com/aaronsb/wp-cloud-run

## 📊 Current Status

- **WordPress Version**: 6.8.1
- **Infrastructure**: Google Cloud Run (Serverless)
- **Database**: Cloud SQL MySQL 8.0
- **Media Storage**: Google Cloud Storage
- **Monthly Cost**: ~$35-60 (with limits enforced)

## 🏗️ Architecture Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│                 │     │                  │     │                 │
│  graph-attract  │────▶│   Cloud Run      │────▶│   Cloud SQL     │
│      .io        │     │  (WordPress)     │     │   (MySQL 8.0)   │
│                 │     │                  │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │                  │
                        │  Cloud Storage   │
                        │  (Media Files)   │
                        │                  │
                        └──────────────────┘
```

## 🛠️ Key Resources

| Resource | Name | Purpose |
|----------|------|---------|
| **Project ID** | `wordpress-bockelie` | GCP Project |
| **Cloud Run Service** | `wp-cloud-run` | WordPress Application |
| **Cloud SQL Instance** | `wordpress-db` | MySQL Database |
| **Storage Bucket** | `wordpress-bockelie-wordpress-media` | Media Files |
| **Service Account** | `wordpress-sa@wordpress-bockelie.iam.gserviceaccount.com` | App Permissions |
| **GitHub Repo** | `aaronsb/wp-cloud-run` | Source Code |

## 📚 Documentation

### Operations
- [Daily Operations Guide](docs/operations/daily-operations.md)
- [WordPress Updates](docs/operations/wordpress-updates.md)
- [Backup & Restore](docs/operations/backup-restore.md)
- [Scaling & Performance](docs/operations/scaling.md)

### Architecture
- [System Architecture](docs/architecture/overview.md)
- [Security Configuration](docs/architecture/security.md)
- [Cost Analysis](docs/architecture/costs.md)

### Troubleshooting
- [Common Issues](docs/troubleshooting/common-issues.md)
- [Error Codes](docs/troubleshooting/error-codes.md)
- [Performance Issues](docs/troubleshooting/performance.md)

### Disaster Recovery
- [Emergency Procedures](docs/recovery/emergency-procedures.md)
- [Data Recovery](docs/recovery/data-recovery.md)
- [Full Restore Process](docs/recovery/full-restore.md)

## 🚨 Emergency Procedures

### High Cost Alert
```bash
# Immediately limit resources
./scripts/set-spending-limits.sh

# Nuclear option - stop all billing
./scripts/emergency-shutdown.sh
```

### Site Down
```bash
# Check service status
gcloud run services describe wp-cloud-run --region=us-central1

# View recent logs
gcloud logging read 'resource.type="cloud_run_revision"' --limit=50

# Force redeploy
git commit --allow-empty -m "Force redeploy" && git push
```

### Database Issues
```bash
# Check Cloud SQL status
gcloud sql instances describe wordpress-db

# Restart if needed
gcloud sql instances restart wordpress-db
```

## 🔐 Security Notes

- WordPress admin is protected by strong passwords
- All secrets stored in Google Secret Manager
- HTTPS enforced via Cloud Run
- Regular automated backups
- Media files served from GCS with public read access

## 💰 Cost Controls

Current limits in place:
- Max 2 Cloud Run instances
- 256MB memory per instance
- Budget alerts at $25, $40, $45, $50
- Cloud SQL can be paused to save ~$25/month

## 🔄 Continuous Deployment

Any push to `main` branch triggers:
1. Cloud Build creates new Docker image
2. Image pushed to Artifact Registry
3. Cloud Run deploys new revision
4. Zero-downtime deployment

## 📧 Monitoring & Alerts

- Budget alerts sent to account email
- Cloud Run errors logged to Cloud Logging
- Uptime monitoring via Cloud Run metrics

## 🤝 Contributing

1. Clone the repository
2. Create feature branch
3. Test locally with `docker-compose up`
4. Push to GitHub - auto-deploys to production

## 📞 Support

This infrastructure is maintained using Claude Code as the primary SRE.
- For changes: Use Claude Code with this repository
- For issues: Check troubleshooting guides first
- For emergencies: Use emergency scripts

---

*Last Updated: June 2025*
*Maintained with Claude Code*