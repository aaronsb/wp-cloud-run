#!/bin/bash

# Script to set up Cloud SQL database and user
# Usage: ./setup-database.sh

set -e

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

echo "Waiting for Cloud SQL instance to be ready..."
gcloud sql instances describe ${CLOUD_SQL_INSTANCE_NAME} --format="value(state)" || echo "Instance not ready yet"

# Wait for instance to be RUNNABLE
while [ "$(gcloud sql instances describe ${CLOUD_SQL_INSTANCE_NAME} --format='value(state)')" != "RUNNABLE" ]; do
    echo "Instance state: $(gcloud sql instances describe ${CLOUD_SQL_INSTANCE_NAME} --format='value(state)' 2>/dev/null || echo 'CREATING')"
    echo "Waiting 30 seconds..."
    sleep 30
done

echo "Cloud SQL instance is ready!"

# Create database
echo "Creating WordPress database..."
gcloud sql databases create wordpress --instance=${CLOUD_SQL_INSTANCE_NAME}

# Create user
echo "Creating WordPress user..."
gcloud sql users create wordpress \
    --instance=${CLOUD_SQL_INSTANCE_NAME} \
    --password="${WORDPRESS_DB_PASSWORD}"

echo "Database setup complete!"
echo
echo "Database connection string: ${GCP_PROJECT_ID}:${GCP_REGION}:${CLOUD_SQL_INSTANCE_NAME}"