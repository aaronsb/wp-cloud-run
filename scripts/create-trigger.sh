#!/bin/bash

# Script to create Cloud Build trigger for WordPress Cloud Run deployment
# Usage: ./create-trigger.sh [PROJECT_ID]

set -e

# Get project ID from argument or current gcloud config
PROJECT_ID=${1:-$(gcloud config get-value project)}

if [ -z "$PROJECT_ID" ]; then
    echo "Error: No project ID provided and no default project set"
    echo "Usage: ./create-trigger.sh [PROJECT_ID]"
    exit 1
fi

echo "Creating Cloud Build trigger for project: $PROJECT_ID"

# Create the trigger
gcloud builds triggers create github \
    --repo-name=wp-cloud-run \
    --repo-owner=aaronsb \
    --branch-pattern="^main$" \
    --build-config=cloudbuild.yaml \
    --description="Deploy WordPress to Cloud Run on push to main branch" \
    --name=wordpress-cloud-run-deploy \
    --include-logs-with-status \
    --substitutions=_SERVICE_NAME=wordpress,_REGION=us-central1,_CLOUD_SQL_INSTANCE=${PROJECT_ID}:us-central1:wordpress-db,_DB_NAME=wordpress,_DB_USER=wordpress,_DB_PASSWORD_SECRET=wordpress-db-password,_AUTH_KEY_SECRET=wordpress-auth-key,_SECURE_AUTH_KEY_SECRET=wordpress-secure-auth-key,_LOGGED_IN_KEY_SECRET=wordpress-logged-in-key,_NONCE_KEY_SECRET=wordpress-nonce-key,_AUTH_SALT_SECRET=wordpress-auth-salt,_SECURE_AUTH_SALT_SECRET=wordpress-secure-auth-salt,_LOGGED_IN_SALT_SECRET=wordpress-logged-in-salt,_NONCE_SALT_SECRET=wordpress-nonce-salt

echo "Trigger created successfully!"
echo
echo "Next steps:"
echo "1. Create Cloud SQL instance if not already done:"
echo "   gcloud sql instances create wordpress-db --database-version=MYSQL_8_0 --tier=db-f1-micro --region=us-central1"
echo
echo "2. Create secrets using: ./scripts/setup-secrets.sh"
echo
echo "3. The trigger will run automatically on your next push to main branch"
echo
echo "To manually run the trigger now:"
echo "   gcloud builds triggers run wordpress-cloud-run-deploy --branch=main"