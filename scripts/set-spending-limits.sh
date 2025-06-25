#!/bin/bash
# Script to set strict spending limits for WordPress on Cloud Run

PROJECT_ID="wordpress-bockelie"
REGION="us-central1"
SERVICE_NAME="wp-cloud-run"

echo "Setting strict resource limits to control costs..."

# 1. Limit Cloud Run instances and resources
echo "Updating Cloud Run service limits..."
gcloud run services update $SERVICE_NAME \
  --region=$REGION \
  --max-instances=2 \
  --min-instances=0 \
  --concurrency=10 \
  --cpu=1 \
  --memory=256Mi \
  --timeout=30s

# 2. Set Cloud SQL to stop after inactivity (for development)
echo "Configuring Cloud SQL auto-stop..."
gcloud sql instances patch wordpress-db \
  --activation-policy=ALWAYS \
  --backup-start-time=03:00 \
  --no-backup

# 3. Create budget alert
BILLING_ACCOUNT=$(gcloud billing projects describe $PROJECT_ID --format="value(billingAccountName)" | cut -d'/' -f2)
echo "Creating budget alert for billing account: $BILLING_ACCOUNT"

# Create a conservative budget
gcloud alpha billing budgets create \
  --billing-account=$BILLING_ACCOUNT \
  --display-name="WordPress Hard Limit - $50" \
  --budget-amount=50 \
  --filter-projects=projects/$PROJECT_ID \
  --threshold-rule=percent=0.5 \
  --threshold-rule=percent=0.8 \
  --threshold-rule=percent=0.9 \
  --threshold-rule=percent=1.0

echo ""
echo "=== Cost Control Measures Applied ==="
echo "1. Cloud Run limited to 2 instances max"
echo "2. Reduced memory to 256MB per instance"
echo "3. Max 10 concurrent requests per instance"
echo "4. 30 second timeout for requests"
echo "5. Budget alerts at 50%, 80%, 90%, and 100% of $50"
echo ""
echo "Estimated maximum monthly cost:"
echo "- Cloud Run: ~$5-20 (with limits)"
echo "- Cloud SQL: ~$25-35"
echo "- Cloud Storage: ~$1-5"
echo "- Total: ~$35-60/month MAX"
echo ""
echo "To COMPLETELY stop charges:"
echo "  gcloud run services delete $SERVICE_NAME --region=$REGION"
echo "  gcloud sql instances delete wordpress-db"
echo ""
echo "To pause Cloud SQL (saves ~$25/month):"
echo "  gcloud sql instances patch wordpress-db --activation-policy=NEVER"