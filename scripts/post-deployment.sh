#!/bin/bash

# Post-deployment setup script for WordPress on Cloud Run
# Run this after WordPress is installed

set -e

echo "=== WordPress Post-Deployment Security & Optimization ==="
echo

echo "1. ESSENTIAL PLUGINS TO INSTALL:"
echo "   - WP Stateless (for Google Cloud Storage media uploads)"
echo "   - Wordfence Security (firewall & malware scanner)"
echo "   - UpdraftPlus (backup to GCS)"
echo "   - Autoptimize (CSS/JS optimization)"
echo "   - WP Super Cache or W3 Total Cache"
echo

echo "2. SECURITY HARDENING STEPS:"
echo "   - Change default 'admin' username"
echo "   - Use strong passwords (min 20 chars)"
echo "   - Enable two-factor authentication"
echo "   - Limit login attempts"
echo "   - Hide WordPress version"
echo

echo "3. CLOUD SQL BACKUP CONFIGURATION:"
echo "   Setting up automatic backups..."

# Enable Cloud SQL automatic backups
gcloud sql instances patch wordpress-db \
  --backup-start-time=03:00 \
  --enable-bin-log \
  --retained-backups-count=7 \
  --retained-transaction-log-days=7

echo "   ✓ Automatic daily backups enabled at 3 AM"
echo "   ✓ 7 days of backups retained"
echo "   ✓ Point-in-time recovery enabled"
echo

echo "4. MONITORING SETUP:"
echo "   Creating uptime check..."

# Create uptime check
gcloud monitoring uptime-check-configs create wordpress-uptime \
  --display-name="WordPress Site Uptime" \
  --monitored-resource="type=uptime_url,labels={host='$(gcloud run services describe bock-wordpress --region=us-south1 --format='value(status.url)' | sed 's|https://||')'}" \
  --http-check-path="/" \
  --check-frequency=300 \
  --timeout=10

echo "   ✓ Uptime monitoring configured (5 min intervals)"
echo

echo "5. PERFORMANCE OPTIMIZATIONS:"
echo "   - Enable Cloud CDN for static assets"
echo "   - Configure browser caching headers"
echo "   - Enable Gzip compression (already in Apache)"
echo "   - Optimize images with WebP"
echo

echo "=== Setup Complete ==="
echo
echo "IMPORTANT NEXT STEPS:"
echo "1. Install WP Stateless plugin immediately"
echo "2. Configure Google Cloud Storage bucket for media"
echo "3. Run WordPress security audit"
echo "4. Set up regular backups with UpdraftPlus"