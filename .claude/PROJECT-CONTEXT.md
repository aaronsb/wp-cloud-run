# Project Context for Claude Code

## Project Overview
This repository manages a WordPress installation running on Google Cloud Run for the domain graph-attract.io. The infrastructure is designed to be fully serverless, auto-scaling, and cost-controlled.

## Key Design Decisions
1. **Serverless Architecture**: Using Cloud Run instead of VMs for automatic scaling and cost efficiency
2. **Ephemeral Storage**: Media files stored in Google Cloud Storage, not on the container
3. **Continuous Deployment**: GitHub pushes automatically trigger deployments
4. **Cost Controls**: Hard limits on resources to prevent bill shock
5. **Security First**: All secrets in Secret Manager, HTTPS enforced

## Current State
- WordPress 6.8.1 running in production
- Site accessible at https://graph-attract.io
- Automated backups running daily
- Monthly costs controlled under $50
- All infrastructure documented

## Common Tasks for Claude Code
1. **Health Checks**: Run commands in QUICK-REFERENCE.md
2. **Updates**: Use scripts/update-wordpress.sh
3. **Cost Issues**: Use scripts/set-spending-limits.sh
4. **Emergencies**: Follow docs/CLAUDE-SRE-RUNBOOK.md
5. **Troubleshooting**: Check docs/troubleshooting/common-issues.md

## Important Constraints
- Never store passwords in code
- Always test major changes locally first
- Keep costs under $50/month budget
- Document any manual changes made
- Alert user if manual intervention needed

## Repository Structure
```
/
├── Dockerfile              # WordPress container definition
├── cloudbuild.yaml        # CI/CD configuration
├── docker-compose.yml     # Local development
├── config/               # WordPress configuration
├── scripts/              # Automation scripts
├── docs/                 # All documentation
│   ├── operations/       # Day-to-day procedures
│   ├── architecture/     # System design docs
│   ├── troubleshooting/  # Problem resolution
│   └── recovery/         # Disaster recovery
├── .env                  # Local secrets (git-ignored)
└── wordpress-gcs-key.json # GCS auth (git-ignored)
```

## Access Information
- All credentials documented in docs/PROJECT-RESOURCES.md
- Service accounts and roles defined for least privilege
- Emergency shutdown procedures in place

## Success Metrics
1. Site uptime > 99%
2. Monthly costs < $50
3. Page load time < 3 seconds
4. Zero security incidents
5. Automated deployments working

This project is designed to be fully managed by Claude Code as an SRE, with comprehensive documentation and automation to handle all common scenarios.