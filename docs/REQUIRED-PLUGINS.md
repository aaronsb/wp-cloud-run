# Required WordPress Plugins

This document lists all plugins required for the graph-attract.io WordPress installation.

## Core Required Plugins

### 1. WP Stateless (REQUIRED)
- **Purpose**: Media storage in Google Cloud Storage
- **Version Policy**: Always latest stable
- **Configuration**: Requires GCS bucket and service account
- **URL**: https://wordpress.org/plugins/wp-stateless/
- **Source**: WordPress.org

### 2. Akismet Anti-spam (REQUIRED)
- **Purpose**: Spam protection for comments and forms
- **Version Policy**: Always latest stable
- **Configuration**: Requires API key (free for personal use)
- **URL**: https://wordpress.org/plugins/akismet/
- **Source**: WordPress.org

### 3. WordPress MCP (REQUIRED)
- **Purpose**: Model Context Protocol integration for AI features
- **Version Policy**: Main branch
- **Configuration**: Requires configuration after activation
- **URL**: https://github.com/Automattic/wordpress-mcp
- **Source**: GitHub repository

### 4. WP Feature API (REQUIRED)
- **Purpose**: Feature flags and experimental features API
- **Version Policy**: Trunk branch
- **Configuration**: Developer-focused, configure as needed
- **URL**: https://github.com/Automattic/wp-feature-api
- **Source**: GitHub repository

## Removed Plugins

### Hello Dolly (REMOVED)
- Default WordPress plugin, not needed

### Plugin Template:
```
### [Plugin Name] (REQUIRED/OPTIONAL)
- **Purpose**: What it does
- **Version Policy**: latest OR specific version
- **Configuration**: Any special setup needed
- **URL**: Plugin homepage
- **License**: GPL, Commercial, etc.
```

## Plugin Categories

### Security
- (Add security plugins here)

### Performance
- (Add caching/optimization plugins here)

### SEO
- (Add SEO plugins here)

### Functionality
- (Add feature plugins here)

### Development
- (Add development/debugging plugins here)

## Update Policy

- **Security plugins**: Always update to latest
- **Feature plugins**: Test before updating
- **Development plugins**: Only in development environment

## Adding Plugins to Build

To add a plugin to the Docker build:

1. Add to `/plugins-manifest.json`
2. Run `./scripts/build-plugins-dockerfile.sh`
3. Commit and push to deploy

Example manifest entry:
```json
"plugin-slug": {
  "version": "latest",
  "source": "wordpress.org",
  "required": true,
  "description": "What this plugin does"
}
```