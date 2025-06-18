#!/bin/bash

# Script to set up custom domain for WordPress on Cloud Run
# Usage: ./setup-custom-domain.sh

set -e

DOMAIN="bockelie.com"
WWW_DOMAIN="www.bockelie.com"
SERVICE_NAME="bock-wordpress"
REGION="us-south1"

echo "Setting up custom domains for WordPress..."
echo "Primary domain: ${DOMAIN}"
echo "WWW domain: ${WWW_DOMAIN}"
echo

# Map the apex domain
echo "Mapping ${DOMAIN} to Cloud Run service..."
gcloud run domain-mappings create \
    --service=${SERVICE_NAME} \
    --domain=${DOMAIN} \
    --region=${REGION}

# Map the www subdomain
echo "Mapping ${WWW_DOMAIN} to Cloud Run service..."
gcloud run domain-mappings create \
    --service=${SERVICE_NAME} \
    --domain=${WWW_DOMAIN} \
    --region=${REGION}

echo
echo "=== DNS Configuration Required ==="
echo
echo "Add these DNS records at your domain registrar:"
echo

# Get the DNS records
echo "For ${DOMAIN} (apex domain):"
gcloud run domain-mappings describe \
    --domain=${DOMAIN} \
    --region=${REGION} \
    --format="value(status.resourceRecords[].rrdata.join(','))"

echo
echo "For ${WWW_DOMAIN}:"
gcloud run domain-mappings describe \
    --domain=${WWW_DOMAIN} \
    --region=${REGION} \
    --format="value(status.resourceRecords[].rrdata.join(','))"

echo
echo "=== WordPress Configuration ==="
echo
echo "After DNS propagation (can take up to 48 hours):"
echo "1. Access WordPress admin at https://${DOMAIN}/wp-admin"
echo "2. Go to Settings > General"
echo "3. Update both URLs to: https://${DOMAIN}"
echo "4. Save changes"
echo
echo "SSL certificates will be automatically provisioned by Google"