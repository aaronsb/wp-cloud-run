# Daily Operations Guide

## Daily Health Checks

### 1. Site Availability
```bash
# Check site is up
curl -s -o /dev/null -w "%{http_code}" https://graph-attract.io

# Check admin access
curl -s -o /dev/null -w "%{http_code}" https://graph-attract.io/wp-admin
```

### 2. Service Status
```bash
# Cloud Run status
gcloud run services describe wp-cloud-run --region=us-central1 --format="value(status.conditions[0].status)"

# Cloud SQL status
gcloud sql instances describe wordpress-db --format="value(state)"

# Recent errors (last 24h)
gcloud logging read 'resource.type="cloud_run_revision" AND severity>=ERROR AND timestamp>="2025-06-24T00:00:00Z"' --limit=10
```

### 3. Resource Usage
```bash
# Check current Cloud Run instances
gcloud run services describe wp-cloud-run --region=us-central1 --format="value(spec.template.metadata.annotations.'autoscaling.knative.dev/maxScale')"

# Database connections
gcloud sql operations list --instance=wordpress-db --limit=5
```

## Common Tasks

### Update WordPress Content
1. Login to https://graph-attract.io/wp-admin
2. Make content changes
3. Media uploads automatically go to Cloud Storage

### Clear Cache (if using caching plugin)
```bash
# No built-in cache, but if you add one:
# WP-CLI would need to be added to the Docker image
```

### View Access Logs
```bash
# Last 50 access logs
gcloud logging read 'resource.type="cloud_run_revision" AND httpRequest.requestUrl!=""' --limit=50 --format=json | jq -r '.httpRequest | "\(.requestMethod) \(.requestUrl) \(.status)"'
```

### Check Media Storage
```bash
# Storage usage
gsutil du -sh gs://wordpress-bockelie-wordpress-media/

# Recent uploads
gsutil ls -l gs://wordpress-bockelie-wordpress-media/2025/06/ | tail -10
```

## Weekly Tasks

### 1. Review Metrics
- Check Cloud Console dashboards
- Review budget spend
- Check for any security alerts

### 2. Update Check
```bash
# Check for WordPress updates
./scripts/update-wordpress.sh

# Check for base image updates
docker pull wordpress:latest
```

### 3. Backup Verification
```bash
# List recent backups
gcloud sql backups list --instance=wordpress-db

# Verify media files are in GCS
gsutil ls gs://wordpress-bockelie-wordpress-media/
```

## Monthly Tasks

### 1. Security Review
- Review user accounts in WordPress
- Check for unusual access patterns
- Update passwords if needed

### 2. Cost Optimization
```bash
# Review costs
gcloud billing accounts list
# Then check in Cloud Console Billing section

# If costs are high, run:
./scripts/set-spending-limits.sh
```

### 3. Performance Review
- Check average response times
- Review Cloud Run scaling events
- Optimize if needed

## Useful Commands Reference

```bash
# Restart service (forces new deployment)
gcloud run services update wp-cloud-run --region=us-central1 --update-env-vars=DEPLOY_TIME=$(date +%s)

# Scale to zero (pause site)
gcloud run services update wp-cloud-run --region=us-central1 --max-instances=0

# Resume from pause
gcloud run services update wp-cloud-run --region=us-central1 --max-instances=2

# Emergency stop all
./scripts/emergency-shutdown.sh
```