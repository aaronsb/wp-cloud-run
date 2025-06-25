#!/bin/bash
# Emergency shutdown script to stop all billable resources

echo "🔥 EMERGENCY SHUTDOWN - This will stop all WordPress services! 🔥"
echo "This will:"
echo "- Delete the Cloud Run service (website will go offline)"
echo "- Stop the Cloud SQL instance (database will be preserved but offline)"
echo "- Remove the load balancer (if any)"
echo ""
read -p "Are you sure you want to proceed? (type 'YES' to confirm): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "Shutdown cancelled."
    exit 1
fi

PROJECT_ID="wordpress-bockelie"
REGION="us-central1"

echo "Stopping Cloud Run service..."
gcloud run services delete wp-cloud-run --region=$REGION --quiet

echo "Stopping Cloud SQL instance..."
gcloud sql instances patch wordpress-db --activation-policy=NEVER

echo "Checking for any load balancers..."
gcloud compute forwarding-rules list --format="value(name)" | while read -r rule; do
    echo "Deleting forwarding rule: $rule"
    gcloud compute forwarding-rules delete $rule --quiet
done

echo ""
echo "✅ All billable services have been stopped!"
echo "Current charges will stop accumulating."
echo ""
echo "To restart everything:"
echo "1. Reactivate Cloud SQL: gcloud sql instances patch wordpress-db --activation-policy=ALWAYS"
echo "2. Redeploy Cloud Run: git push origin main (will trigger automatic deployment)"
echo ""
echo "Your data is preserved in:"
echo "- Cloud SQL database (stopped but not deleted)"
echo "- Google Cloud Storage bucket (minimal ongoing cost ~$0.02/GB/month)"