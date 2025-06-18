#!/bin/bash

# Script to generate secure passwords for .env file
# Usage: ./generate-passwords.sh

set -e

# Function to generate a secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

echo "Generating secure passwords..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
fi

# Generate new WordPress database password
WP_DB_PASS=$(generate_password)
echo "Generated WordPress database password: $WP_DB_PASS"

# Generate new local database password
LOCAL_DB_PASS=$(generate_password)
echo "Generated local database password: $LOCAL_DB_PASS"

# Update .env file with new passwords
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/WORDPRESS_DB_PASSWORD=.*/WORDPRESS_DB_PASSWORD=$WP_DB_PASS/" .env
    sed -i '' "s/LOCAL_DB_PASSWORD=.*/LOCAL_DB_PASSWORD=$LOCAL_DB_PASS/" .env
else
    # Linux
    sed -i "s/WORDPRESS_DB_PASSWORD=.*/WORDPRESS_DB_PASSWORD=$WP_DB_PASS/" .env
    sed -i "s/LOCAL_DB_PASSWORD=.*/LOCAL_DB_PASSWORD=$LOCAL_DB_PASS/" .env
fi

echo
echo "Passwords have been generated and saved to .env"
echo "Keep this file secure and never commit it to version control!"
echo
echo "Next steps:"
echo "1. Review and update other settings in .env if needed"
echo "2. Run ./scripts/setup-secrets.sh to create Google Cloud secrets"
echo "3. For local development: docker-compose up"