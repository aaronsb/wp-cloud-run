# Claude Code SRE Runbook

> This runbook is specifically designed for Claude Code to manage the graph-attract.io WordPress infrastructure.

## 🎯 Primary Objectives
1. Keep the site running and accessible
2. Maintain costs under $50/month
3. Ensure data is backed up and secure
4. Apply updates in a controlled manner

## 🔍 Regular Health Checks

When asked to "check if everything is OK", run these commands:

```bash
# 1. Site availability
curl -s -o /dev/null -w "Site Status: %{http_code}\n" https://graph-attract.io

# 2. Service status
gcloud run services describe wp-cloud-run --region=us-central1 --format="value(status.conditions[0].status)"

# 3. Database status
gcloud sql instances describe wordpress-db --format="value(state)"

# 4. Recent errors (last 2 hours)
gcloud logging read 'resource.type="cloud_run_revision" AND severity>=ERROR AND timestamp>"2 hours ago"' --limit=5

# 5. Current month's cost
echo "Check billing at: https://console.cloud.google.com/billing"
```

## 🚨 Emergency Response Procedures

### High Cost Alert Response

**Budget Alerts are configured at: 50% ($25), 80% ($40), 90% ($45), 100% ($50)**

1. When you receive a budget alert email, check current spend:
   ```bash
   echo "Check billing at: https://console.cloud.google.com/billing/budgets?project=wordpress-bockelie"
   ```

2. Check what's causing high costs:
   ```bash
   gcloud run services describe wp-cloud-run --region=us-central1 --format=json | jq '.spec.template.spec'
   ```

3. Apply spending limits:
   ```bash
   ./scripts/set-spending-limits.sh
   ```

4. If at 90% or above, consider emergency shutdown:
   ```bash
   ./scripts/emergency-shutdown.sh
   ```

### Site Down Response
1. Check service status:
   ```bash
   gcloud run services describe wp-cloud-run --region=us-central1
   ```

2. Check for deployment issues:
   ```bash
   gcloud builds list --limit=3
   ```

3. Force redeploy if needed:
   ```bash
   git commit --allow-empty -m "Force redeploy to fix issues" && git push origin main
   ```

### Database Connection Error
1. Verify Cloud SQL is running:
   ```bash
   gcloud sql instances describe wordpress-db
   ```

2. If stopped, restart:
   ```bash
   gcloud sql instances patch wordpress-db --activation-policy=ALWAYS
   ```

3. Verify connection configuration:
   ```bash
   gcloud run services describe wp-cloud-run --region=us-central1 --format=json | jq '.spec.template.metadata.annotations'
   ```

## 📅 Maintenance Tasks

### WordPress Core Updates
1. Check for updates:
   ```bash
   ./scripts/update-wordpress.sh
   ```

2. If update available, update Dockerfile and deploy:
   ```bash
   git add Dockerfile
   git commit -m "Update WordPress to [VERSION]"
   git push origin main
   ```

### Plugin Updates
Since filesystem is ephemeral, plugin updates must be built into the image:

1. Document needed updates
2. Modify Dockerfile to include specific plugin versions
3. Test and deploy

### Certificate Renewal
- Certificates auto-renew via Google-managed SSL
- If issues occur, check domain mapping:
  ```bash
  gcloud beta run domain-mappings describe --domain=graph-attract.io --region=us-central1
  ```

## 💾 Backup Procedures

### Database Backup
Automatic backups run daily. To create manual backup:
```bash
gcloud sql backups create --instance=wordpress-db --description="Manual backup $(date +%Y%m%d)"
```

### Media Backup
Media is in GCS, inherently durable. To create snapshot:
```bash
gsutil -m cp -r gs://wordpress-bockelie-wordpress-media gs://wordpress-bockelie-backup-$(date +%Y%m%d)/
```

## 🔧 Common Operations

### Scale Up for Traffic
```bash
gcloud run services update wp-cloud-run --region=us-central1 \
  --max-instances=5 \
  --cpu=2 \
  --memory=1Gi
```

### Scale Down to Save Costs
```bash
gcloud run services update wp-cloud-run --region=us-central1 \
  --max-instances=2 \
  --cpu=1 \
  --memory=256Mi
```

### View Recent Logs
```bash
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="wp-cloud-run"' \
  --limit=50 --format="value(timestamp,severity,textPayload)"
```

### Check Media Storage Usage
```bash
gsutil du -sh gs://wordpress-bockelie-wordpress-media/
```

## 📊 Performance Optimization

If site is slow:

1. Check current resources:
   ```bash
   gcloud run services describe wp-cloud-run --region=us-central1 --format=json | jq '.spec.template.spec.resources'
   ```

2. Enable always-on instance to avoid cold starts:
   ```bash
   gcloud run services update wp-cloud-run --region=us-central1 --min-instances=1
   ```

3. Increase resources if needed:
   ```bash
   gcloud run services update wp-cloud-run --region=us-central1 --memory=512Mi
   ```

## 🔐 Security Tasks

### Review Access Logs
```bash
gcloud logging read 'resource.type="cloud_run_revision" AND httpRequest.userAgent=~"bot|crawler|scanner"' \
  --limit=20 --format=json | jq '.httpRequest | {url:.requestUrl, agent:.userAgent, ip:.remoteIp}'
```

### Update Secrets
```bash
# List current secrets
gcloud secrets list

# Update a secret (example for DB password)
echo -n "NEW_PASSWORD" | gcloud secrets versions add wordpress-db-password --data-file=-
```

## 📈 Monitoring Commands

### Check Traffic Patterns
```bash
gcloud logging read 'resource.type="cloud_run_revision" AND httpRequest.requestUrl!=""' \
  --format="value(timestamp)" | cut -d'T' -f2 | cut -d':' -f1 | sort | uniq -c
```

### Check Error Rate
```bash
gcloud logging read 'resource.type="cloud_run_revision" AND httpRequest.status>=400' \
  --format="value(httpRequest.status)" | sort | uniq -c
```

## 🔄 Deployment Process

All deployments happen automatically via GitHub:

1. Make changes to code
2. Commit with descriptive message
3. Push to main branch
4. Monitor build:
   ```bash
   watch -n 5 'gcloud builds list --limit=1'
   ```

## 💡 Important Notes

- **Never** store credentials in code
- **Always** test major changes locally first
- **Monitor** costs weekly
- **Backup** before major updates
- **Document** any manual changes

## 🆘 When to Alert User

Alert the user immediately if:
- Costs exceed $40 in a month
- Site is down for more than 10 minutes
- Database backups are failing
- Security breach is suspected
- Manual intervention is required

---

*This runbook is designed for Claude Code. Last updated: June 2025*