#!/bin/bash

# Script to create Google Cloud secrets for WordPress
# Usage: ./setup-secrets.sh

set -e

# Load environment variables if .env exists
if [ -f .env ]; then
    echo "Loading configuration from .env file..."
    export $(grep -v '^#' .env | xargs)
else
    echo "Warning: .env file not found. Copy .env.example to .env and configure it."
    exit 1
fi

echo "Setting up WordPress secrets in Google Cloud Secret Manager..."
echo "Project: ${GCP_PROJECT_ID}"
echo "Region: ${GCP_REGION}"
echo "Cloud SQL Instance: ${CLOUD_SQL_INSTANCE_NAME}"
echo

# Function to create or update a secret
create_secret() {
    local secret_name=$1
    local secret_value=$2
    
    # Check if secret exists
    if gcloud secrets describe "$secret_name" &>/dev/null; then
        echo "Secret $secret_name already exists, updating..."
        echo -n "$secret_value" | gcloud secrets versions add "$secret_name" --data-file=-
    else
        echo "Creating secret $secret_name..."
        echo -n "$secret_value" | gcloud secrets create "$secret_name" --data-file=-
    fi
}

# Database password from .env or prompt
if [ -n "$WORDPRESS_DB_PASSWORD" ]; then
    echo "Using database password from .env file"
    db_password="$WORDPRESS_DB_PASSWORD"
else
    read -sp "Enter database password: " db_password
    echo
fi
create_secret "wordpress-db-password" "$db_password"

# Generate WordPress salts
echo "Generating WordPress salts..."

# You can get these from https://api.wordpress.org/secret-key/1.1/salt/
# or generate them locally
generate_salt() {
    openssl rand -base64 64 | tr -d '\n'
}

create_secret "wordpress-auth-key" "$(generate_salt)"
create_secret "wordpress-secure-auth-key" "$(generate_salt)"
create_secret "wordpress-logged-in-key" "$(generate_salt)"
create_secret "wordpress-nonce-key" "$(generate_salt)"
create_secret "wordpress-auth-salt" "$(generate_salt)"
create_secret "wordpress-secure-auth-salt" "$(generate_salt)"
create_secret "wordpress-logged-in-salt" "$(generate_salt)"
create_secret "wordpress-nonce-salt" "$(generate_salt)"

echo "All secrets have been created successfully!"
echo
echo "Configuration Summary:"
echo "- Project: ${GCP_PROJECT_ID}"
echo "- Region: ${GCP_REGION}"
echo "- Cloud SQL: ${GCP_PROJECT_ID}:${GCP_REGION}:${CLOUD_SQL_INSTANCE_NAME}"
echo
echo "Next steps:"
echo "1. Create Cloud SQL instance if not already done:"
echo "   gcloud sql instances create ${CLOUD_SQL_INSTANCE_NAME} --database-version=MYSQL_8_0 --tier=db-f1-micro --region=${GCP_REGION}"
echo
echo "2. Create database and user:"
echo "   gcloud sql databases create wordpress --instance=${CLOUD_SQL_INSTANCE_NAME}"
echo "   gcloud sql users create wordpress --instance=${CLOUD_SQL_INSTANCE_NAME} --password='${WORDPRESS_DB_PASSWORD}'"
echo
echo "3. Push to GitHub to trigger deployment:"
echo "   git push origin main"
echo
echo "4. After deployment, visit your Cloud Run URL to complete WordPress setup"
echo "   Your Cloud Run URL will be shown in the deployment logs"