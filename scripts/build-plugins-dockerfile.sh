#!/bin/bash
# Build Dockerfile plugin section from manifest

echo "🔨 Building Plugin Dockerfile Section"
echo "===================================="

# Check if manifest exists
if [ ! -f "plugins-manifest.json" ]; then
    echo "❌ Error: plugins-manifest.json not found!"
    exit 1
fi

# Create plugin installation section
cat > Dockerfile.plugins << 'EOF'
# ==============================================
# WordPress Plugin Installations
# Generated from plugins-manifest.json
# ==============================================
# DO NOT EDIT THIS SECTION MANUALLY
# Update plugins-manifest.json and run:
# ./scripts/build-plugins-dockerfile.sh
# ==============================================

# Create plugin directories
RUN mkdir -p /var/www/html/wp-content/plugins \
             /var/www/html/wp-content/themes \
             /var/www/html/wp-content/uploads

EOF

# Remove unwanted plugins
echo "🗑️  Removing unwanted plugins..."
jq -r '.remove_plugins[]?' plugins-manifest.json 2>/dev/null | while read -r plugin; do
    echo "  - Removing $plugin"
    cat >> Dockerfile.plugins << EOF
# Remove: $plugin
RUN rm -rf /var/www/html/wp-content/plugins/${plugin}

EOF
done

# Process plugins
echo "📦 Processing plugins..."
jq -c '.plugins | to_entries[] | select(.value.required != false)' plugins-manifest.json | while read -r entry; do
    plugin=$(echo "$entry" | jq -r '.key')
    version=$(echo "$entry" | jq -r '.value.version')
    source=$(echo "$entry" | jq -r '.value.source')
    repository=$(echo "$entry" | jq -r '.value.repository // empty')
    
    echo "  - Installing $plugin from $source ($version)"
    
    if [ "$source" == "wordpress.org" ]; then
        if [ "$version" == "latest" ]; then
            VERSION_SUFFIX="latest-stable"
        else
            VERSION_SUFFIX="$version"
        fi
        
        cat >> Dockerfile.plugins << EOF
# Plugin: $plugin (WordPress.org)
RUN cd /var/www/html/wp-content/plugins && \\
    curl -sLO https://downloads.wordpress.org/plugin/${plugin}.${VERSION_SUFFIX}.zip && \\
    unzip -q ${plugin}.${VERSION_SUFFIX}.zip && \\
    rm ${plugin}.${VERSION_SUFFIX}.zip && \\
    chown -R www-data:www-data ${plugin}

EOF
    elif [ "$source" == "github" ]; then
        cat >> Dockerfile.plugins << EOF
# Plugin: $plugin (GitHub: $repository)
RUN cd /var/www/html/wp-content/plugins && \\
    git clone --depth 1 --branch ${version} https://github.com/${repository}.git ${plugin} && \\
    rm -rf ${plugin}/.git && \\
    chown -R www-data:www-data ${plugin}

EOF
    fi
done

# Process themes
echo "🎨 Processing themes..."
jq -r '.themes | to_entries[] | "\(.key)|\(.value.version)"' plugins-manifest.json 2>/dev/null | while IFS='|' read -r theme version; do
    echo "  - Installing theme $theme ($version)"
    
    if [ "$version" == "latest" ]; then
        VERSION_SUFFIX="latest-stable"  
    else
        VERSION_SUFFIX="$version"
    fi
    
    cat >> Dockerfile.plugins << EOF
# Theme: $theme
RUN cd /var/www/html/wp-content/themes && \\
    curl -sLO https://downloads.wordpress.org/theme/${theme}.${VERSION_SUFFIX}.zip && \\
    unzip -q ${theme}.${VERSION_SUFFIX}.zip && \\
    rm ${theme}.${VERSION_SUFFIX}.zip && \\
    chown -R www-data:www-data ${theme}

EOF
done

# Set permissions
cat >> Dockerfile.plugins << 'EOF'
# Set proper permissions
RUN chown -R www-data:www-data /var/www/html/wp-content && \
    find /var/www/html/wp-content -type d -exec chmod 755 {} \; && \
    find /var/www/html/wp-content -type f -exec chmod 644 {} \;
EOF

echo ""
echo "✅ Plugin Dockerfile section generated!"
echo ""
echo "Next steps:"
echo "1. Review Dockerfile.plugins"
echo "2. Copy the content into your main Dockerfile (before the final CMD)"
echo "3. Commit and push to deploy"
echo ""
echo "To see what will be installed:"
echo "cat Dockerfile.plugins"