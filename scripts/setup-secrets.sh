#!/bin/bash

# Script to create Google Cloud secrets for WordPress
# Usage: ./setup-secrets.sh

set -e

echo "Setting up WordPress secrets in Google Cloud Secret Manager..."

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

# Database password
read -sp "Enter database password: " db_password
echo
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
echo "Next steps:"
echo "1. Update cloudbuild.yaml with your Cloud SQL instance details"
echo "2. Push to GitHub to trigger deployment"
echo "3. Visit your Cloud Run URL to complete WordPress setup"