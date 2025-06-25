#!/bin/bash
# Simpler approach: Daily budget check with Cloud Scheduler

PROJECT_ID="wordpress-bockelie"
REGION="us-central1"

echo "Setting up daily budget check..."

# Enable Cloud Scheduler
gcloud services enable cloudscheduler.googleapis.com

# Create a simple Cloud Function that checks budget
mkdir -p daily-budget-check
cd daily-budget-check

cat > index.js << 'EOF'
const {google} = require('googleapis');

exports.checkBudget = async (req, res) => {
  const PROJECT_ID = process.env.GCP_PROJECT;
  const BUDGET_AMOUNT = 50; // Your budget
  const SHUTDOWN_THRESHOLD = 0.9; // Shutdown at 90%
  
  try {
    // Get current billing info
    const auth = await google.auth.getClient({
      scopes: ['https://www.googleapis.com/auth/cloud-platform']
    });
    
    const billing = google.cloudbilling({version: 'v1', auth});
    
    // This is a simplified example - you'd need to implement actual cost checking
    console.log('Checking daily spend...');
    
    // For now, let's check if services are running and estimate
    const {exec} = require('child_process');
    
    // Check if we should shutdown
    exec('gcloud run services describe wp-cloud-run --region=us-central1 --format="value(status.conditions[0].status)"', (error, stdout) => {
      if (stdout.trim() === 'True') {
        console.log('Services are running, checking if shutdown needed...');
        // In reality, you'd check actual costs here
        // For safety, this is just a template
      }
    });
    
    res.status(200).send('Budget check completed');
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Error checking budget');
  }
};
EOF

cat > package.json << 'EOF'
{
  "name": "daily-budget-check",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "googleapis": "^105.0.0"
  }
}
EOF

cd ..

echo ""
echo "=== Automated Budget Response Options ==="
echo ""
echo "Option 1: Cloud Function with Pub/Sub (Recommended)"
echo "- Real-time response to budget alerts"
echo "- Automatically scales down at 90% threshold"
echo "- Run: ./scripts/setup-budget-automation.sh"
echo ""
echo "Option 2: Manual Daily Checks"
echo "- Use existing emergency shutdown script"
echo "- Set calendar reminder at 80% budget alert"
echo "- Run: ./scripts/emergency-shutdown.sh when needed"
echo ""
echo "Option 3: Prepaid Credits"
echo "- Purchase Google Cloud credits in advance"
echo "- Hard limit on spending"
echo "- Contact Google Cloud sales"
echo ""
echo "IMPORTANT: Google Cloud does not offer automatic hard cutoffs."
echo "These solutions help minimize overage but require setup."