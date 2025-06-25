# Budget Automation Guide

## The Challenge
Google Cloud does **not** provide automatic hard cutoffs when budgets are exceeded. Your services will continue running and accruing charges even after hitting budget limits.

## Available Solutions

### 1. 🤖 Automated Response System (Cloud Function + Pub/Sub)

**How it works:**
- Budget alerts trigger a Cloud Function via Pub/Sub
- At 90% threshold, automatically:
  - Scales Cloud Run to zero instances
  - Stops Cloud SQL instance
  - Sends notification

**Setup:**
```bash
./scripts/setup-budget-automation.sh
```

**Then update your budget:**
1. Go to [Billing Budgets](https://console.cloud.google.com/billing/budgets)
2. Edit "WordPress Monthly Budget"
3. Add Pub/Sub topic: `projects/wordpress-bockelie/topics/budget-alerts`

**Pros:**
- Fully automated
- Near real-time response
- Prevents most overages

**Cons:**
- Site goes offline at 90% budget
- Requires Cloud Function (small additional cost)
- Not a true hard cutoff

### 2. 📅 Manual Response with Alerts

**Current Setup:**
- Email alerts at 50%, 80%, 90%, 100% of budget
- Manual intervention required

**Response Plan:**
- **50% ($25)**: Monitor usage
- **80% ($40)**: Run `./scripts/set-spending-limits.sh`
- **90% ($45)**: Consider `./scripts/emergency-shutdown.sh`
- **100% ($50)**: Immediately run emergency shutdown

**Pros:**
- Human judgment on actions
- No additional infrastructure
- Can optimize before shutdown

**Cons:**
- Requires immediate response to emails
- Can miss alerts if away
- Charges continue until action taken

### 3. 💳 Prepaid Credits / Billing Account Limits

**Options:**
- Purchase Google Cloud credits with fixed amount
- Set up separate billing account with spending limit
- Use prepaid credit card with low limit

**Contact:** Google Cloud Sales for prepaid options

### 4. 🕐 Scheduled Daily Checks

**Setup Cloud Scheduler to:**
```bash
# Run daily at 8 AM
gcloud scheduler jobs create http daily-budget-check \
  --location=$REGION \
  --schedule="0 8 * * *" \
  --uri="https://check-budget-function-url" \
  --http-method=GET
```

## Recommended Approach

For a **$50/month budget**, we recommend:

1. **Keep current email alerts** (already configured)
2. **Set up automated response** for peace of mind:
   ```bash
   ./scripts/setup-budget-automation.sh
   ```
3. **Monitor weekly** to optimize before hitting limits

## Cost Breakdown to Avoid Surprises

With current limits, maximum possible charges:
- **Cloud Run**: Max 2 instances × 24h × 30d = ~$20/month
- **Cloud SQL**: db-g1-small = $25.55/month
- **Storage**: ~$5/month for typical usage
- **Total**: ~$50/month

## Emergency Commands

If you need to stop charges immediately:

```bash
# Stop everything NOW
./scripts/emergency-shutdown.sh

# Or manually:
gcloud run services update wp-cloud-run --region=us-central1 --max-instances=0
gcloud sql instances patch wordpress-db --activation-policy=NEVER
```

## Testing Your Setup

To test automated response without waiting for real charges:

1. Temporarily lower budget to $5
2. Wait for response to trigger
3. Reset budget to $50
4. Restart services

## Important Notes

- **No solution is 100% foolproof** - Google can still charge for:
  - Storage (minimal, ~$0.02/GB/month)
  - Network egress if site is DDoS'd
  - Cloud Function execution costs
- **Best practice**: Check billing dashboard weekly
- **Consider**: Setting up a separate GCP project for better isolation

---

*Remember: The only true hard cutoff is deleting all resources, which would result in data loss.*