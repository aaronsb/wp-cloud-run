#!/bin/bash
# Script to set up automated budget response system

PROJECT_ID="wordpress-bockelie"
REGION="us-central1"
BUDGET_PUBSUB_TOPIC="budget-alerts"
FUNCTION_NAME="budget-response"

echo "Setting up automated budget response system..."

# 1. Enable required APIs
echo "Enabling Cloud Functions API..."
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable pubsub.googleapis.com

# 2. Create Pub/Sub topic for budget alerts
echo "Creating Pub/Sub topic..."
gcloud pubsub topics create $BUDGET_PUBSUB_TOPIC 2>/dev/null || echo "Topic already exists"

# 3. Create Cloud Function directory
mkdir -p budget-function
cd budget-function

# 4. Create Cloud Function code
cat > index.js << 'EOF'
const {CloudRunClient} = require('@google-cloud/run');
const {InstancesClient} = require('@google-cloud/sql');

const PROJECT_ID = process.env.GCP_PROJECT;
const CLOUD_RUN_SERVICE = 'wp-cloud-run';
const CLOUD_SQL_INSTANCE = 'wordpress-db';
const REGION = 'us-central1';
const THRESHOLD_ACTION = 0.9; // Take action at 90%

exports.budgetResponseHandler = async (pubsubMessage, context) => {
  const data = JSON.parse(Buffer.from(pubsubMessage.data, 'base64').toString());
  
  console.log('Budget alert received:', data);
  
  const costAmount = data.costAmount;
  const budgetAmount = data.budgetAmount;
  const threshold = costAmount / budgetAmount;
  
  console.log(`Current spend: $${costAmount}, Budget: $${budgetAmount}, Threshold: ${threshold * 100}%`);
  
  if (threshold >= THRESHOLD_ACTION) {
    console.log('THRESHOLD EXCEEDED! Taking protective action...');
    
    try {
      // 1. Scale Cloud Run to zero
      const runClient = new CloudRunClient();
      const serviceName = `projects/${PROJECT_ID}/locations/${REGION}/services/${CLOUD_RUN_SERVICE}`;
      
      await runClient.updateService({
        service: {
          name: serviceName,
          template: {
            metadata: {
              annotations: {
                'autoscaling.knative.dev/maxScale': '0'
              }
            }
          }
        },
        updateMask: 'template.metadata.annotations'
      });
      
      console.log('Cloud Run service scaled to zero');
      
      // 2. Stop Cloud SQL instance
      const sqlClient = new InstancesClient();
      await sqlClient.patch({
        project: PROJECT_ID,
        instance: CLOUD_SQL_INSTANCE,
        body: {
          settings: {
            activationPolicy: 'NEVER'
          }
        }
      });
      
      console.log('Cloud SQL instance stopped');
      
      // 3. Send notification (you could add email/SMS here)
      console.log('EMERGENCY: Services stopped due to budget threshold exceeded!');
      
    } catch (error) {
      console.error('Error executing protective actions:', error);
    }
  } else if (threshold >= 0.8) {
    console.log('Warning: 80% of budget consumed');
    // Could add warning actions here
  }
};
EOF

# 5. Create package.json
cat > package.json << 'EOF'
{
  "name": "budget-response",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/run": "^1.0.0",
    "@google-cloud/sql": "^3.0.0"
  }
}
EOF

# 6. Deploy Cloud Function
echo "Deploying Cloud Function..."
gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=. \
  --entry-point=budgetResponseHandler \
  --trigger-topic=$BUDGET_PUBSUB_TOPIC \
  --service-account=wordpress-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --set-env-vars="GCP_PROJECT=$PROJECT_ID"

cd ..

# 7. Update budget to send alerts to Pub/Sub
echo ""
echo "Now you need to update your budget to send alerts to Pub/Sub:"
echo "1. Go to: https://console.cloud.google.com/billing/budgets"
echo "2. Click on 'WordPress Monthly Budget'"
echo "3. Under 'Actions', add:"
echo "   - Connect to Pub/Sub topic: projects/$PROJECT_ID/topics/$BUDGET_PUBSUB_TOPIC"
echo ""
echo "Or run this command:"
echo "gcloud alpha billing budgets update dab3b11e-13d4-41d3-8c3a-0490bc93b532 \\"
echo "  --billing-account=00FF9A-009D32-54C463 \\"
echo "  --add-pubsub-topic=projects/$PROJECT_ID/topics/$BUDGET_PUBSUB_TOPIC"
echo ""
echo "WARNING: This will automatically stop your services at 90% budget!"
echo "To disable: gcloud functions delete $FUNCTION_NAME --region=$REGION"