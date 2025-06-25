# Persistent Storage Options for WordPress on Cloud Run

## Current Limitation
Cloud Run's filesystem is ephemeral - all changes are lost when containers restart. This affects:
- Plugin updates
- Theme updates  
- Media uploads (currently handled by WP Stateless)
- WordPress core updates

## Option 1: Google Cloud Filestore (Recommended)

### Overview
Mount a managed NFS share to persist `/wp-content` directory

### Setup
```bash
# Create Filestore instance (1TB minimum)
gcloud filestore instances create wordpress-content \
  --zone=us-central1-a \
  --tier=BASIC_HDD \
  --file-share=name="wordpress",capacity=1TB \
  --network=name="default"

# Get the IP address
gcloud filestore instances describe wordpress-content \
  --zone=us-central1-a \
  --format="value(networks[0].ipAddresses[0])"
```

### Modify Cloud Run deployment
```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: wp-cloud-run
spec:
  template:
    spec:
      containers:
      - image: wordpress
        volumeMounts:
        - name: wordpress-content
          mountPath: /var/www/html/wp-content
      volumes:
      - name: wordpress-content
        nfs:
          server: FILESTORE_IP
          path: /wordpress
```

### Pros
- Normal WordPress admin experience
- All updates work as expected
- No need for WP Stateless
- Shared across all container instances

### Cons  
- **Cost**: ~$204/month for 1TB (minimum size)
- Requires VPC connector (~$10/month)
- More complex setup

### Monthly Cost Impact
- Current: ~$35-60
- With Filestore: ~$250-285 😱

## Option 2: Cloud Storage FUSE (Experimental)

### Overview
Mount Google Cloud Storage bucket as filesystem

### Setup
```dockerfile
# Add to Dockerfile
RUN echo "deb https://packages.cloud.google.com/apt gcsfuse-focal main" | tee /etc/apt/sources.list.d/gcsfuse.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN apt-get update && apt-get install -y gcsfuse

# Mount script
RUN echo '#!/bin/bash\n\
mkdir -p /var/www/html/wp-content\n\
gcsfuse --implicit-dirs wordpress-bockelie-wordpress-media /var/www/html/wp-content\n\
apache2-foreground' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
```

### Pros
- Uses existing GCS bucket
- Cheaper than Filestore
- Works with Cloud Run

### Cons
- Performance issues (not true filesystem)
- Compatibility problems with some plugins
- Still experimental

## Option 3: External WordPress Management

### Overview  
Use wp-cli in CI/CD pipeline to manage plugins

### Implementation
```yaml
# In cloudbuild.yaml
steps:
  - name: 'wordpress:cli'
    entrypoint: 'bash'
    args:
    - '-c'
    - |
      wp plugin install akismet --version=5.3
      wp plugin install wordfence --version=7.10
      wp theme install twentytwentyfour
```

### Maintain a plugins.json
```json
{
  "plugins": {
    "akismet": "5.3",
    "wordfence": "7.10",
    "wp-stateless": "latest"
  },
  "themes": {
    "twentytwentyfour": "latest"
  }
}
```

## Option 4: Hybrid Approach (Recommended for Budget)

### Keep current setup but add:

1. **Development Mode Toggle**
   ```bash
   # Enable persistent storage temporarily
   gcloud run services update wp-cloud-run \
     --add-volume=name=wp-content,type=emptyDir \
     --add-volume-mount=volume=wp-content,mount-path=/var/www/html/wp-content
   ```

2. **Plugin Management Workflow**
   - Test updates in admin panel
   - Export plugin list
   - Rebuild container monthly

3. **Automated Plugin Updates**
   ```bash
   # Script to update all plugins in Dockerfile
   ./scripts/update-all-plugins.sh
   ```

## Option 5: Different Hosting (Nuclear Option)

If conventional management is critical:
- **Google Compute Engine**: Traditional VM (~$25/month)
- **Cloud SQL + GCE**: Full control (~$50/month)
- **Managed WordPress hosts**: WP Engine, Kinsta, etc.

## Recommendation

Given your budget constraints ($50/month):

1. **Short term**: Keep current setup
   - Document plugin versions needed
   - Update Dockerfile monthly
   - Use WP Stateless for media

2. **Medium term**: Implement Option 3
   - Automated plugin management via CI/CD
   - Still serverless and scalable

3. **If budget allows**: Option 1 (Filestore)
   - True WordPress experience
   - But 5x more expensive

## Decision Matrix

| Option | Monthly Cost | Update Experience | Complexity | Reliability |
|--------|--------------|-------------------|------------|-------------|
| Current | $35-60 | Manual/Complex | Low | High |
| Filestore | $250+ | Native/Easy | High | High |
| GCS FUSE | $40-65 | Native/Buggy | Medium | Medium |
| CI/CD Managed | $35-60 | Automated | Medium | High |
| Traditional VM | $50-100 | Native/Easy | Low | Medium |

The harsh reality: Cloud Run's serverless benefits come with the trade-off of ephemeral storage. True persistent storage is expensive in Google Cloud.