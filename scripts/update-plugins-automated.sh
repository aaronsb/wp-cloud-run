#!/bin/bash
# Automated plugin updater for WordPress Docker builds

echo "🔄 WordPress Plugin Auto-Updater"
echo "================================"

# Create a temporary WordPress instance to check for updates
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Download WordPress CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar

# Download WordPress core (just for plugin checks)
./wp-cli.phar core download --skip-content

# Create plugins manifest file
MANIFEST_FILE="../plugins-manifest.json"

# Check if manifest exists, create if not
if [ ! -f "$MANIFEST_FILE" ]; then
    echo '{
  "plugins": {
    "wp-stateless": {
      "version": "latest",
      "source": "wordpress.org"
    }
  },
  "themes": {
    "twentytwentyfour": {
      "version": "latest",
      "source": "wordpress.org"
    }
  }
}' > $MANIFEST_FILE
fi

# Generate new Dockerfile segment
cat > ../Dockerfile.plugins << 'EOF'
# Auto-generated plugin installations
# Generated on: $(date)
# DO NOT EDIT MANUALLY - Use scripts/update-plugins-automated.sh

# Install plugins from manifest
RUN mkdir -p /var/www/html/wp-content/plugins /var/www/html/wp-content/themes

EOF

# Read manifest and generate download commands
echo "📦 Processing plugins from manifest..."
PLUGINS=$(jq -r '.plugins | to_entries[] | "\(.key):\(.value.version)"' $MANIFEST_FILE)

while IFS=: read -r plugin version; do
    echo "  - $plugin ($version)"
    
    if [ "$version" == "latest" ]; then
        # Get latest version from WordPress.org
        LATEST_VER=$(curl -s "https://api.wordpress.org/plugins/info/1.0/$plugin.json" | jq -r '.version' || echo "latest-stable")
        VERSION_STR="$LATEST_VER"
    else
        VERSION_STR="$version"
    fi
    
    cat >> ../Dockerfile.plugins << EOF
# Plugin: $plugin v$VERSION_STR
RUN cd /var/www/html/wp-content/plugins && \\
    curl -sO https://downloads.wordpress.org/plugin/$plugin.$VERSION_STR.zip && \\
    unzip -q $plugin.$VERSION_STR.zip && \\
    rm $plugin.$VERSION_STR.zip

EOF
done <<< "$PLUGINS"

# Clean up
cd ..
rm -rf $TEMP_DIR

echo ""
echo "✅ Plugin update check complete!"
echo "📄 Review Dockerfile.plugins for the generated commands"
echo ""
echo "To apply updates:"
echo "1. Review the generated Dockerfile.plugins"
echo "2. Integrate into main Dockerfile"
echo "3. Commit and push to trigger deployment"