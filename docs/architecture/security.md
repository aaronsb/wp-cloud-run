# Security Architecture

## Overview
This document outlines the security configuration for the WordPress Cloud Run deployment, including headers, policies, and access controls.

## Security Headers Configuration

### Content Security Policy (CSP)
The CSP implementation uses a dual approach to balance security with functionality:

#### Admin Area (`/wp-admin/*`)
```apache
Header always set Content-Security-Policy "default-src * 'unsafe-inline' 'unsafe-eval' data: blob:; frame-ancestors 'self';"
```
- **Permissive policy** to support Gutenberg block editor
- Allows all sources (`*`) for maximum compatibility
- Permits `data:` and `blob:` URLs for dynamic content
- Required for posts created via API (e.g., WordPress Feature API)

#### Public Pages
```apache
Header always set Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval'; frame-ancestors 'self';"
```
- **Restrictive policy** for visitor-facing content
- Limits sources to self and HTTPS origins
- Prevents clickjacking with `frame-ancestors`

### Other Security Headers

1. **X-Frame-Options**: `SAMEORIGIN`
   - Prevents clickjacking attacks
   - Allows framing only from same origin

2. **X-Content-Type-Options**: `nosniff`
   - Prevents MIME type sniffing
   - Forces browsers to respect declared content types

3. **X-XSS-Protection**: `1; mode=block`
   - Enables browser XSS filtering
   - Blocks page rendering if attack detected

4. **Referrer-Policy**: `strict-origin-when-cross-origin`
   - Controls referrer information sent
   - Balances privacy with functionality

## Access Controls

### File Protection
```apache
<FilesMatch "^(wp-config\.php|\.htaccess|\.htpasswd|\.svn|\.git)">
    Require all denied
</FilesMatch>
```
- Blocks access to sensitive configuration files
- Prevents exposure of version control files

### Upload Security
```apache
<Directory "/var/www/html/wp-content/uploads">
    <FilesMatch "\.php$">
        Require all denied
    </FilesMatch>
</Directory>
```
- Prevents PHP execution in uploads directory
- Mitigates malicious file upload attacks

## Server Configuration

### Information Disclosure
- `ServerTokens Prod`: Hides Apache version
- `ServerSignature Off`: Removes server signature
- `Options -Indexes`: Disables directory browsing

### Request Limits
- `LimitRequestBody 67108864`: 64MB upload limit
- Matches PHP configuration for consistency

## Cloud Infrastructure Security

### Secret Management
- All sensitive data stored in Google Secret Manager
- Secrets mounted as environment variables at runtime
- No credentials in code or configuration files

### Network Security
- HTTPS enforced by Cloud Run
- Automatic SSL/TLS certificate management
- No direct database exposure (Cloud SQL proxy)

### Identity & Access Management
- Service account with minimal required permissions
- Separate accounts for different services
- Regular permission audits recommended

## WordPress-Specific Security

### Plugin Management
- Automated plugin updates via CI/CD
- No manual plugin installation allowed
- Version control for all plugin changes

### Authentication
- Strong password requirements enforced
- WordPress salts stored in Secret Manager
- No default admin accounts

### Database Security
- Cloud SQL with private IP
- Automated daily backups
- Point-in-time recovery enabled

## Known Considerations

### Gutenberg Editor Compatibility
The WordPress block editor (Gutenberg) requires a permissive CSP due to:
- Dynamic JavaScript execution
- Inline styles and scripts
- API-created content with custom blocks
- Third-party block plugins

This is why the admin area has a more relaxed CSP than public pages.

### Media Storage
- WP Stateless plugin handles media uploads
- Files stored in Google Cloud Storage
- Public read access for media files
- No PHP execution in media URLs

## Security Monitoring

### Available Logs
- Cloud Run access logs
- Cloud SQL audit logs
- Cloud Storage access logs
- WordPress application logs

### Recommended Monitoring
- Failed login attempts
- 404 errors for sensitive paths
- Unusual traffic patterns
- Resource usage spikes

## Regular Security Tasks

1. **Monthly**
   - Review user accounts
   - Check for plugin updates
   - Verify backup integrity

2. **Quarterly**
   - Audit service account permissions
   - Review security headers effectiveness
   - Update WordPress core if needed

3. **Annually**
   - Full security audit
   - Penetration testing (if applicable)
   - Disaster recovery drill

## Emergency Response

For security incidents:
1. Check Cloud Run logs for suspicious activity
2. Review Cloud SQL connections
3. Verify no unauthorized file changes
4. Use emergency shutdown if compromise suspected
5. Restore from known-good backup if needed

See [Emergency Procedures](../recovery/emergency-procedures.md) for detailed steps.