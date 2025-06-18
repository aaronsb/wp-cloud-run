# WordPress on Google Cloud Run

This repository contains a WordPress setup optimized for Google Cloud Run with continuous deployment from GitHub.

## Features

- ✅ Serverless WordPress on Cloud Run (no OS maintenance)
- ✅ Automatic deployments on git push
- ✅ Cloud SQL integration
- ✅ Environment-based configuration
- ✅ Secure secret management
- ✅ Optimized for performance with OPcache

## Prerequisites

1. Google Cloud Project with billing enabled
2. Cloud SQL MySQL instance
3. GitHub repository connected to Cloud Build
4. Required APIs enabled:
   - Cloud Run API
   - Cloud Build API
   - Cloud SQL Admin API
   - Secret Manager API

## Initial Setup

### 1. Create Cloud SQL Instance

```bash
gcloud sql instances create wordpress-db \
  --database-version=MYSQL_8_0 \
  --tier=db-f1-micro \
  --region=us-central1
```

### 2. Create Database and User

```bash
# Create database
gcloud sql databases create wordpress \
  --instance=wordpress-db

# Create user
gcloud sql users create wordpress \
  --instance=wordpress-db \
  --password=YOUR_SECURE_PASSWORD
```

### 3. Create Secrets in Secret Manager

```bash
# Database password
echo -n "YOUR_DB_PASSWORD" | gcloud secrets create wordpress-db-password --data-file=-

# WordPress salts (generate from https://api.wordpress.org/secret-key/1.1/salt/)
echo -n "YOUR_AUTH_KEY" | gcloud secrets create wordpress-auth-key --data-file=-
echo -n "YOUR_SECURE_AUTH_KEY" | gcloud secrets create wordpress-secure-auth-key --data-file=-
# ... repeat for all salt keys
```

### 4. Update cloudbuild.yaml

Edit `cloudbuild.yaml` and update these values:
- `_CLOUD_SQL_INSTANCE`: Your Cloud SQL connection name (PROJECT:REGION:INSTANCE)
- `_DB_NAME`: Your database name (default: wordpress)
- `_DB_USER`: Your database user (default: wordpress)

### 5. Connect GitHub Repository

1. Go to Cloud Console > Cloud Build > Triggers
2. Click "Connect Repository"
3. Select GitHub and authenticate
4. Choose this repository
5. Create a trigger for the main branch

## Local Development

### Using Docker Compose

Create a `docker-compose.yml` for local development:

```yaml
version: '3.8'

services:
  wordpress:
    build: .
    ports:
      - "8080:80"
    environment:
      PORT: 80
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: root
      WORDPRESS_DB_PASSWORD: rootpassword
    volumes:
      - ./wp-content:/var/www/html/wp-content
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

Run with: `docker-compose up`

## Deployment

### Automatic Deployment

Simply push to your main branch:

```bash
git add .
git commit -m "Update WordPress configuration"
git push origin main
```

Cloud Build will automatically:
1. Build the Docker image
2. Push to Container Registry
3. Deploy to Cloud Run

### Manual Deployment

```bash
# Build and push image
docker build -t gcr.io/YOUR_PROJECT_ID/wordpress-cloudrun .
docker push gcr.io/YOUR_PROJECT_ID/wordpress-cloudrun

# Deploy to Cloud Run
gcloud run deploy wordpress \
  --image gcr.io/YOUR_PROJECT_ID/wordpress-cloudrun \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --add-cloudsql-instances YOUR_PROJECT:us-central1:wordpress-db
```

## Post-Deployment Steps

### 1. Complete WordPress Installation

Visit your Cloud Run URL and complete the WordPress installation wizard.

### 2. Install Required Plugins

For media uploads to work properly, install:
- **WP Stateless** - Integrates with Google Cloud Storage
- **WP Offload Media Lite** - Alternative GCS plugin

### 3. Configure HTTPS

Cloud Run automatically provides HTTPS. Update WordPress settings:
- WordPress Address (URL): https://your-service-url.run.app
- Site Address (URL): https://your-service-url.run.app

### 4. Custom Domain (Optional)

```bash
gcloud run domain-mappings create \
  --service wordpress \
  --domain yourdomain.com \
  --region us-central1
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| WORDPRESS_DB_HOST | Cloud SQL instance connection name | Yes |
| WORDPRESS_DB_NAME | Database name | Yes |
| WORDPRESS_DB_USER | Database username | Yes |
| WORDPRESS_DB_PASSWORD | Database password (use Secret Manager) | Yes |
| WORDPRESS_DEBUG | Enable debug mode (true/false) | No |
| WORDPRESS_TABLE_PREFIX | Database table prefix | No |
| WORDPRESS_MULTISITE | Enable multisite (true/false) | No |

## Troubleshooting

### Database Connection Issues

1. Verify Cloud SQL instance is running
2. Check Cloud SQL connection in Cloud Run service
3. Verify database credentials in Secret Manager

### Performance Issues

1. Increase Cloud Run CPU/Memory allocation
2. Enable Cloud CDN for static assets
3. Use Redis Memorystore for object caching

### File Upload Issues

1. Install GCS plugin (WP Stateless)
2. Configure Cloud Storage bucket
3. Set proper CORS policy on bucket

## Security Best Practices

1. ✅ Use Secret Manager for sensitive data
2. ✅ Enable Cloud SQL private IP
3. ✅ Restrict Cloud Run ingress to "internal and cloud load balancing"
4. ✅ Use Cloud Armor for DDoS protection
5. ✅ Regular backups with Cloud SQL automated backups

## Cost Optimization

- Use minimum instances = 0 for dev environments
- Set maximum instances based on expected traffic
- Use Cloud SQL stop/start for non-production
- Enable Cloud CDN to reduce Cloud Run requests

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.