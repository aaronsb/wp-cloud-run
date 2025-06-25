# WordPress Cloud Run Project Summary

## What We Built
A fully automated, serverless WordPress installation on Google Cloud Run with:
- Custom domain (graph-attract.io)
- Automated plugin management via CI/CD
- Cost controls under $50/month
- Continuous deployment from GitHub

## Key Accomplishments

### 1. Infrastructure Setup
- **Project**: wordpress-bockelie
- **Services**: Cloud Run + Cloud SQL + Cloud Storage
- **Domain**: graph-attract.io with SSL
- **Deployment**: Automatic from GitHub pushes

### 2. Cost Controls
- **Budget Alert**: $50/month with alerts at 50%, 80%, 90%, 100%
- **Resource Limits**: Max 2 instances, 256MB RAM each
- **Emergency Scripts**: 
  - `./scripts/set-spending-limits.sh` - Apply limits
  - `./scripts/emergency-shutdown.sh` - Stop everything

### 3. Plugin Management System
- **Manifest-Based**: Define plugins in `plugins-manifest.json`
- **Supports**: WordPress.org and GitHub repositories
- **Build Script**: `./scripts/build-plugins-dockerfile.sh`
- **Current Plugins**:
  - WP Stateless (media storage)
  - Akismet (anti-spam)
  - wordpress-mcp (AI features)
  - wp-feature-api (feature flags)

### 4. WordPress Configuration
- **Version**: 6.8.1 (updated from 6.5)
- **URLs**: Hardcoded to graph-attract.io in wp-config.php
- **Database**: Cloud SQL MySQL 8.0 with daily backups
- **Media**: Google Cloud Storage via WP Stateless

### 5. Key Fixes Applied
- Database connection via Cloud SQL socket
- WordPress URL configuration for custom domain
- Plugin branch references (trunk vs main)
- Admin access requires trailing slash (/wp-admin/)

### 6. Documentation Created
- Daily operations guide
- Troubleshooting common issues
- Budget automation options
- Plugin management guide
- Future roadmap (including caching strategy)
- Recovery procedures

## Important Commands

```bash
# Check site status
curl -I https://graph-attract.io

# View logs
gcloud logging read 'resource.type="cloud_run_revision"' --limit=50

# Update plugins
1. Edit plugins-manifest.json
2. Run ./scripts/build-plugins-dockerfile.sh
3. Copy to Dockerfile
4. Push to deploy

# Emergency shutdown
./scripts/emergency-shutdown.sh

# Check costs
https://console.cloud.google.com/billing
```

## Lessons Learned
1. Cloud Run's ephemeral filesystem requires different approach
2. CI/CD plugin management is superior to admin updates
3. Automattic repos use 'trunk' not 'main'
4. Budget alerts don't stop spending - need manual intervention
5. Caching will be essential for zero-scale performance

## Next Steps (Documented in Roadmap)
1. Monitor costs for 2-4 weeks
2. Implement Cloudflare caching when ready
3. Consider monitoring service
4. Regular plugin updates via manifest

## Repository Structure
```
/wp-cloud-run/
├── Dockerfile                 # Main container definition
├── plugins-manifest.json      # Plugin definitions
├── cloudbuild.yaml           # CI/CD configuration
├── scripts/                  # Automation tools
├── docs/                     # Comprehensive documentation
└── config/                   # WordPress configuration
```

## Access Points
- **Site**: https://graph-attract.io
- **Admin**: https://graph-attract.io/wp-admin/
- **GitHub**: https://github.com/aaronsb/wp-cloud-run
- **Console**: https://console.cloud.google.com/home/dashboard?project=wordpress-bockelie

This project is now fully documented and ready for Claude Code to manage as your SRE.