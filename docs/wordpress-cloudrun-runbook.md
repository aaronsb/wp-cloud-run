# WordPress on Cloud Run - Complete Setup Runbook

## Prerequisites
- Google Cloud account with billing enabled
- GitHub account
- Domain name (optional, for custom domain)
- Local development environment with Docker and gcloud CLI

## Step 1: Create New Google Cloud Project

```bash
# Create project (use a unique project ID)
gcloud projects create YOUR-PROJECT-ID --name="Your WordPress Site"

# Set as active project
gcloud config set project YOUR-PROJECT-ID

# Link billing account (get account ID with: gcloud billing accounts list)
gcloud billing projects link YOUR-PROJECT-ID --billing-account=BILLING_ACCOUNT_ID

# Enable required APIs
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  sqladmin.googleapis.com \
  artifactregistry.googleapis.com \
  containerregistry.googleapis.com
```

## Step 2: Create Service Account

```bash
# Create service account for Cloud Run
gcloud iam service-accounts create wordpress-sa \
  --display-name="WordPress Service Account" \
  --description="Service account for WordPress on Cloud Run"

# Grant necessary permissions
PROJECT_ID=$(gcloud config get-value project)

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:wordpress-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:wordpress-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:wordpress-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"
```

## Step 3: Create Cloud SQL Instance

```bash
# Create Cloud SQL instance (adjust tier based on needs)
gcloud sql instances create wordpress-db \
  --database-version=MYSQL_8_0 \
  --tier=db-g1-small \
  --region=us-central1 \
  --availability-type=zonal \
  --backup-start-time=03:00 \
  --enable-bin-log \
  --retained-backups-count=7 \
  --retained-transaction-log-days=7

# Create database
gcloud sql databases create wordpress --instance=wordpress-db

# Generate secure password
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
echo "Database password: $DB_PASSWORD"

# Create database user
gcloud sql users create wordpress \
  --instance=wordpress-db \
  --password=$DB_PASSWORD
```

## Step 4: Create Secrets

```bash
# Create database password secret
echo -n "$DB_PASSWORD" | gcloud secrets create wordpress-db-password --data-file=-

# Generate WordPress salts
for secret in auth-key secure-auth-key logged-in-key nonce-key auth-salt secure-auth-salt logged-in-salt nonce-salt; do
  openssl rand -base64 64 | tr -d '\n' | \
  gcloud secrets create wordpress-$secret --data-file=-
done

# Grant service account access to secrets
gcloud secrets add-iam-policy-binding wordpress-db-password \
  --member="serviceAccount:wordpress-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

## Step 5: Set Up GitHub Repository

1. Fork or clone: https://github.com/aaronsb/wp-cloud-run
2. Update the following files:

### Update cloudbuild.yaml
```yaml
substitutions:
  _SERVICE_NAME: 'wordpress'
  _REGION: 'us-central1'  # Change to your preferred region
  _CLOUD_SQL_INSTANCE: 'YOUR-PROJECT-ID:us-central1:wordpress-db'
```

### Update .env (create from .env.example)
```
GCP_PROJECT_ID=YOUR-PROJECT-ID
GCP_REGION=us-central1
CLOUD_SQL_INSTANCE_NAME=wordpress-db
```

## Step 6: Deploy to Cloud Run

### Option A: Deploy via Console (Recommended)
1. Go to Cloud Run in Google Cloud Console
2. Click "Create Service"
3. Select "Continuously deploy from a repository"
4. Connect your GitHub repository
5. Configure:
   - Branch: main
   - Build Type: Dockerfile
   - Service name: wordpress
   - Region: us-central1
   - Authentication: Allow unauthenticated
   - CPU allocation: CPU is only allocated during request processing
   - Minimum instances: 0 (or 1 to avoid cold starts)
   - Maximum instances: 10

### Option B: Deploy via Command Line
```bash
# Build and deploy manually
gcloud run deploy wordpress \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --service-account wordpress-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --add-cloudsql-instances $PROJECT_ID:us-central1:wordpress-db \
  --set-env-vars WORDPRESS_DB_HOST=$PROJECT_ID:us-central1:wordpress-db \
  --set-env-vars WORDPRESS_DB_NAME=wordpress \
  --set-env-vars WORDPRESS_DB_USER=wordpress \
  --set-secrets WORDPRESS_DB_PASSWORD=wordpress-db-password:latest \
  --min-instances 0 \
  --max-instances 10 \
  --cpu 1 \
  --memory 512Mi
```

## Step 7: Complete WordPress Installation

1. Visit your Cloud Run URL: https://YOUR-SERVICE-URL.run.app
2. Complete WordPress installation wizard
3. Choose strong admin username (not "admin")
4. Use a strong password
5. Save credentials securely

## Step 8: Configure Media Storage

Since Cloud Run's filesystem is ephemeral, configure Google Cloud Storage for media:

```bash
# Create storage bucket
gsutil mb -p $PROJECT_ID -c standard -l us-central1 gs://$PROJECT_ID-wordpress-media/

# Set public access for media files
gsutil iam ch allUsers:objectViewer gs://$PROJECT_ID-wordpress-media

# Create service account key for plugin
gcloud iam service-accounts keys create gcs-key.json \
  --iam-account=wordpress-sa@$PROJECT_ID.iam.gserviceaccount.com
```

In WordPress admin:
1. Install "WP Stateless" or "WP Offload Media Lite" plugin
2. Configure with your bucket name
3. Upload the service account key
4. Test by uploading an image

## Step 9: Security Hardening

1. **Install Security Plugins**:
   - Wordfence Security or Sucuri
   - Limit Login Attempts Reloaded
   - Two-Factor Authentication

2. **Configure Headers** (already in Dockerfile):
   - X-Frame-Options
   - X-Content-Type-Options
   - Content-Security-Policy

3. **Regular Backups**:
   - Install UpdraftPlus
   - Configure backups to Google Cloud Storage
   - Schedule daily database backups

## Step 10: Custom Domain (Optional)

```bash
# Map custom domain
gcloud run domain-mappings create \
  --service wordpress \
  --domain yourdomain.com \
  --region us-central1

# Get DNS records to add at your registrar
gcloud run domain-mappings describe \
  --domain yourdomain.com \
  --region us-central1
```

Add the provided DNS records at your domain registrar. SSL certificates are automatically provisioned.

## Step 11: Performance Optimization

1. **Enable Cloud CDN** (optional):
   - Set up Cloud Load Balancer
   - Enable Cloud CDN
   - Configure caching rules

2. **Install Caching Plugin**:
   - W3 Total Cache or WP Rocket
   - Configure object caching
   - Enable page caching

3. **Optimize Images**:
   - Install image optimization plugin
   - Enable WebP conversion
   - Lazy load images

## Maintenance Tasks

### Weekly
- Review security plugin alerts
- Check for WordPress updates
- Monitor Cloud Run metrics

### Monthly
- Review access logs for suspicious activity
- Test backup restoration
- Update plugins and themes

### Quarterly
- Security audit
- Performance review
- Cost optimization review

## Troubleshooting

### Database Connection Error
```bash
# Check Cloud SQL connection
gcloud run services describe wordpress --region=us-central1 --format="yaml" | grep cloudsql

# Verify secrets
gcloud secrets versions list wordpress-db-password
```

### High Latency
- Increase minimum instances to 1
- Upgrade Cloud SQL tier
- Enable Cloud CDN

### Storage Issues
- Verify GCS bucket permissions
- Check WP Stateless configuration
- Ensure service account has storage.objects.create permission

## Cost Optimization

1. **Cloud Run**: 
   - Set minimum instances to 0 for dev/staging
   - Use CPU allocation "only during request processing"

2. **Cloud SQL**:
   - Use zonal availability for non-critical sites
   - Enable "Stop your database instance after inactivity"
   - Right-size the instance tier

3. **Storage**:
   - Set lifecycle rules on media bucket
   - Archive old backups

## Estimated Monthly Costs (Low Traffic Site)
- Cloud Run: $5-20 (depends on traffic)
- Cloud SQL (db-g1-small): $25-35
- Cloud Storage: $1-5
- **Total**: ~$35-60/month

## Important Notes

1. **Never commit secrets** to version control
2. **Always use HTTPS** (automatic with Cloud Run)
3. **Regular backups** are essential
4. **Monitor costs** via billing alerts
5. **Keep WordPress updated** for security

## Useful Commands

```bash
# View logs
gcloud run logs read --service=wordpress --region=us-central1 --limit=50

# Update environment variables
gcloud run services update wordpress --update-env-vars KEY=VALUE --region=us-central1

# Connect to Cloud SQL
gcloud sql connect wordpress-db --user=wordpress

# List all resources
gcloud run services list
gcloud sql instances list
gcloud secrets list
```

---

This runbook provides a complete, production-ready WordPress deployment on Cloud Run with proper security, performance, and maintenance considerations.