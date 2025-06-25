# WordPress Cloud Run Maintenance Guide

## Updating WordPress Core

WordPress core updates are handled through Docker image updates:

1. **Check for updates:**
   ```bash
   ./scripts/update-wordpress.sh
   ```

2. **The update process:**
   - Updates the Dockerfile with the latest WordPress version
   - Commit and push triggers automatic deployment
   - Cloud Build creates new image and deploys

3. **After deployment:**
   - Visit `/wp-admin/upgrade.php` if prompted
   - Test all critical functionality
   - Check that plugins are compatible

## Updating Plugins and Themes

Since the filesystem is ephemeral, plugin/theme updates require special handling:

### Option 1: Update via Admin (Temporary)
- Updates work during the session
- Changes are lost when container restarts
- Good for testing compatibility

### Option 2: Build Custom Image (Permanent)
Add to Dockerfile:
```dockerfile
# Install specific plugins
RUN cd /var/www/html/wp-content/plugins && \
    curl -O https://downloads.wordpress.org/plugin/wp-stateless.latest-stable.zip && \
    unzip wp-stateless.latest-stable.zip && \
    rm wp-stateless.latest-stable.zip
```

### Option 3: Use Composer (Recommended for teams)
Create `composer.json` for plugin management

## Security Updates

**Critical security updates should be applied immediately:**

1. Update WordPress core version in Dockerfile
2. Monitor WordPress security advisories
3. Enable automatic security updates (for minor versions):
   ```php
   define( 'WP_AUTO_UPDATE_CORE', 'minor' );
   ```

## Backup Procedures

### Database Backups
- Automatic daily backups via Cloud SQL
- 7-day retention configured
- Manual backup:
  ```bash
  gcloud sql backups create --instance=wordpress-db
  ```

### Media Backups
- Already in Google Cloud Storage
- Create bucket snapshot:
  ```bash
  gsutil -m cp -r gs://wordpress-bockelie-wordpress-media gs://backup-bucket-name
  ```

## Monitoring

1. **Check Cloud Run metrics:**
   ```bash
   gcloud run services describe wp-cloud-run --region=us-central1
   ```

2. **View logs:**
   ```bash
   gcloud logging read 'resource.type="cloud_run_revision"' --limit=50
   ```

3. **Cost monitoring:**
   - Check billing dashboard regularly
   - Review budget alerts

## Performance Optimization

1. **Review Cloud Run settings:**
   - Adjust min/max instances based on traffic
   - Increase memory if needed
   - Monitor cold start frequency

2. **Database optimization:**
   ```sql
   -- Run in Cloud SQL
   OPTIMIZE TABLE wp_posts, wp_postmeta, wp_options;
   ```

3. **Cache optimization:**
   - Consider adding Redis for object caching
   - Enable Cloud CDN for static assets

## Troubleshooting

### Site is slow
1. Check Cloud Run metrics for CPU/memory usage
2. Review Cloud SQL slow query log
3. Verify WP Stateless is working correctly

### Can't update plugins
- Remember: filesystem is ephemeral
- Updates must be built into image
- Or use development mode temporarily

### Database connection errors
1. Verify Cloud SQL is running
2. Check service account permissions
3. Verify secrets are accessible

## Monthly Maintenance Checklist

- [ ] Review and apply WordPress core updates
- [ ] Check for plugin security advisories  
- [ ] Review Cloud Run metrics and adjust limits
- [ ] Verify backups are running successfully
- [ ] Check billing and budget alerts
- [ ] Review error logs for issues
- [ ] Test disaster recovery procedure
- [ ] Update documentation as needed