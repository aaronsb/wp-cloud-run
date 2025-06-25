# Quick Reference Card

## 🚀 Most Used Commands

```bash
# Check if site is up
curl -I https://graph-attract.io

# View recent errors
gcloud logging read 'severity>=ERROR' --limit=10

# Force redeploy
git commit --allow-empty -m "Redeploy" && git push

# Emergency cost control
./scripts/set-spending-limits.sh

# Full emergency stop
./scripts/emergency-shutdown.sh
```

## 📞 Key URLs
- **Site**: https://graph-attract.io
- **Admin**: https://graph-attract.io/wp-admin/ (trailing slash required)
- **Console**: https://console.cloud.google.com/?project=wordpress-bockelie
- **GitHub**: https://github.com/aaronsb/wp-cloud-run

## 🔧 Service Names
- **Project**: wordpress-bockelie
- **Cloud Run**: wp-cloud-run
- **Database**: wordpress-db
- **Bucket**: wordpress-bockelie-wordpress-media

## 💰 Cost Controls
- Budget: $50/month
- Max instances: 2
- Memory: 256MB each
- To pause: `gcloud sql instances patch wordpress-db --activation-policy=NEVER`

## 🚨 Emergency Contacts
- Check billing alerts in email
- Use Claude Code for all operations
- Full docs in `/docs` directory