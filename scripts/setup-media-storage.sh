#!/bin/bash

# Script to set up Google Cloud Storage for WordPress media
# Usage: ./setup-media-storage.sh

set -e

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

BUCKET_NAME="${GCP_PROJECT_ID}-wordpress-media"
SERVICE_ACCOUNT="wordpress-gcs-sa"

echo "Setting up Google Cloud Storage for WordPress media..."
echo "Bucket name: ${BUCKET_NAME}"
echo

# Create the bucket
echo "Creating GCS bucket..."
gsutil mb -p ${GCP_PROJECT_ID} -c standard -l ${GCP_REGION} gs://${BUCKET_NAME}/ || echo "Bucket may already exist"

# Set bucket permissions for public read
echo "Setting bucket permissions..."
gsutil iam ch allUsers:objectViewer gs://${BUCKET_NAME}

# Enable CORS for WordPress
echo "Configuring CORS..."
cat > /tmp/cors.json << EOF
[
    {
      "origin": ["*"],
      "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
      "responseHeader": ["*"],
      "maxAgeSeconds": 3600
    }
]
EOF

gsutil cors set /tmp/cors.json gs://${BUCKET_NAME}
rm /tmp/cors.json

# Create service account for WordPress
echo "Creating service account..."
gcloud iam service-accounts create ${SERVICE_ACCOUNT} \
    --display-name="WordPress GCS Service Account" || echo "Service account may already exist"

# Grant permissions to the service account
echo "Granting permissions..."
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"

# Create and download service account key
echo "Creating service account key..."
gcloud iam service-accounts keys create wordpress-gcs-key.json \
    --iam-account=${SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com

echo
echo "=== Google Cloud Storage Setup Complete ==="
echo
echo "Bucket name: ${BUCKET_NAME}"
echo "Service account: ${SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
echo "Key file: wordpress-gcs-key.json"
echo
echo "NEXT STEPS:"
echo "1. Install WP Stateless plugin in WordPress"
echo "2. Configure plugin with:"
echo "   - Bucket: ${BUCKET_NAME}"
echo "   - Upload the key file: wordpress-gcs-key.json"
echo "3. Test by uploading an image"
echo
echo "IMPORTANT: Keep wordpress-gcs-key.json secure and add to .gitignore"