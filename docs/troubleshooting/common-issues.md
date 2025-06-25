# Common Issues & Solutions

## Site Not Loading

### Symptoms
- Browser shows connection timeout
- 500/502/503 errors

### Diagnosis
```bash
# Check service status
gcloud run services describe wp-cloud-run --region=us-central1 --format="value(status.conditions[0].message)"

# Check recent logs
gcloud logging read 'resource.type="cloud_run_revision" AND severity>=WARNING' --limit=20

# Check if instances are running
gcloud run revisions list --service=wp-cloud-run --region=us-central1
```

### Solutions
1. **If service is not running:**
   ```bash
   # Force redeploy
   git commit --allow-empty -m "Force redeploy" && git push
   ```

2. **If "no available instances":**
   ```bash
   # Increase minimum instances
   gcloud run services update wp-cloud-run --region=us-central1 --min-instances=1
   ```

3. **If memory errors in logs:**
   ```bash
   # Increase memory
   gcloud run services update wp-cloud-run --region=us-central1 --memory=512Mi
   ```

## Database Connection Error

### Symptoms
- "Error establishing a database connection"
- Site loads but shows database error

### Diagnosis
```bash
# Check Cloud SQL status
gcloud sql instances describe wordpress-db --format="value(state)"

# Check Cloud SQL connection in Cloud Run
gcloud run services describe wp-cloud-run --region=us-central1 --format="value(spec.template.metadata.annotations.'run.googleapis.com/cloudsql-instances')"
```

### Solutions
1. **If Cloud SQL is stopped:**
   ```bash
   gcloud sql instances patch wordpress-db --activation-policy=ALWAYS
   ```

2. **If connection string is wrong:**
   ```bash
   gcloud run services update wp-cloud-run --region=us-central1 \
     --add-cloudsql-instances=wordpress-bockelie:us-central1:wordpress-db
   ```

3. **If credentials are wrong:**
   - Verify secrets in Secret Manager
   - Update the secret if needed
   - Redeploy the service

## Media Upload Failures

### Symptoms
- "Failed to upload" error
- Images not displaying
- Media library empty

### Diagnosis
```bash
# Check WP Stateless plugin status
curl -s https://graph-attract.io/wp-content/plugins/ | grep stateless

# Check GCS bucket permissions
gsutil iam get gs://wordpress-bockelie-wordpress-media | grep wordpress-gcs-sa

# Test bucket access
gsutil ls gs://wordpress-bockelie-wordpress-media/
```

### Solutions
1. **If plugin is deactivated:**
   - Login to wp-admin
   - Activate WP Stateless plugin
   - Reconfigure with GCS credentials

2. **If permissions error:**
   ```bash
   # Re-grant permissions
   gsutil iam ch serviceAccount:wordpress-gcs-sa@wordpress-bockelie.iam.gserviceaccount.com:objectAdmin \
     gs://wordpress-bockelie-wordpress-media
   ```

## High Costs / Budget Alerts

### Symptoms
- Email alerts about budget thresholds
- Unexpected charges

### Diagnosis
```bash
# Check current instances
gcloud run services describe wp-cloud-run --region=us-central1 \
  --format="value(spec.template.spec.containerConcurrency,spec.template.metadata.annotations.'autoscaling.knative.dev/maxScale')"

# Check request counts
gcloud logging read 'resource.type="cloud_run_revision" AND httpRequest.requestUrl!=""' \
  --format="value(timestamp)" | wc -l
```

### Solutions
1. **Immediate cost reduction:**
   ```bash
   ./scripts/set-spending-limits.sh
   ```

2. **Emergency shutdown:**
   ```bash
   ./scripts/emergency-shutdown.sh
   ```

3. **Pause Cloud SQL:**
   ```bash
   gcloud sql instances patch wordpress-db --activation-policy=NEVER
   ```

## SSL Certificate Issues

### Symptoms
- Browser shows "Not Secure"
- Certificate errors
- HTTPS not working

### Diagnosis
```bash
# Check domain mapping status
gcloud beta run domain-mappings describe --domain=graph-attract.io \
  --region=us-central1 --format="value(status.conditions[0].message)"

# Check DNS
dig graph-attract.io A +short
```

### Solutions
1. **If certificate pending:**
   - Wait up to 24 hours for provisioning
   - Ensure all DNS records are correct

2. **If DNS not resolving:**
   - Check domain registrar settings
   - Verify all 4 A records are present

## Plugin/Theme Updates Not Persisting

### Symptoms
- Updates disappear after container restart
- Changes lost randomly

### Explanation
Cloud Run containers are ephemeral - filesystem changes don't persist.

### Solutions
1. **For testing only:**
   - Updates work within the session
   - Note which updates are needed

2. **For permanent updates:**
   - Add to Dockerfile:
     ```dockerfile
     # Install specific plugin version
     RUN cd /var/www/html/wp-content/plugins && \
         curl -O https://downloads.wordpress.org/plugin/plugin-name.version.zip && \
         unzip plugin-name.version.zip && rm plugin-name.version.zip
     ```
   - Commit and push to deploy

## Performance Issues

### Symptoms
- Slow page loads
- Timeouts
- High latency

### Diagnosis
```bash
# Check instance CPU/memory
gcloud run services describe wp-cloud-run --region=us-central1 \
  --format="value(spec.template.spec.resources)"

# Check concurrent requests
gcloud logging read 'resource.type="cloud_run_revision" AND httpRequest.latency!=""' \
  --format="value(httpRequest.latency)" --limit=100
```

### Solutions
1. **Increase resources:**
   ```bash
   gcloud run services update wp-cloud-run --region=us-central1 \
     --cpu=2 --memory=1Gi --concurrency=50
   ```

2. **Add minimum instances:**
   ```bash
   gcloud run services update wp-cloud-run --region=us-central1 --min-instances=1
   ```

3. **Enable Cloud CDN** (requires load balancer setup)

## Container Startup Failures

### Symptoms
- Deployment fails
- "Container failed to start" errors

### Diagnosis
```bash
# Check build logs
gcloud builds list --limit=1 --format="value(id)"
gcloud builds log $(gcloud builds list --limit=1 --format="value(id)")

# Check container logs
gcloud logging read 'resource.type="cloud_run_revision" AND "container failed"' --limit=10
```

### Solutions
1. **If build fails:**
   - Check Dockerfile syntax
   - Verify base image exists
   - Check for typos in configuration

2. **If runtime fails:**
   - Check wp-config.php for errors
   - Verify environment variables
   - Check file permissions in Dockerfile