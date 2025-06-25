#!/bin/bash
# Plugin management helper for Cloud Run WordPress

ACTION=$1
PLUGIN_NAME=$2
PLUGIN_VERSION=$3

if [ -z "$ACTION" ]; then
    echo "Usage: $0 [add|remove|list] [plugin-name] [version]"
    echo "Example: $0 add akismet 5.3"
    exit 1
fi

DOCKERFILE_PATH="./Dockerfile"

case $ACTION in
    "add")
        if [ -z "$PLUGIN_NAME" ]; then
            echo "Error: Plugin name required"
            exit 1
        fi
        
        VERSION_STRING=""
        if [ ! -z "$PLUGIN_VERSION" ]; then
            VERSION_STRING=".$PLUGIN_VERSION"
        else
            VERSION_STRING=".latest-stable"
        fi
        
        # Check if plugin section exists
        if ! grep -q "# WordPress Plugins" $DOCKERFILE_PATH; then
            echo "" >> $DOCKERFILE_PATH
            echo "# WordPress Plugins" >> $DOCKERFILE_PATH
            echo "RUN mkdir -p /var/www/html/wp-content/plugins" >> $DOCKERFILE_PATH
        fi
        
        # Add plugin installation
        echo "RUN cd /var/www/html/wp-content/plugins && \\" >> $DOCKERFILE_PATH
        echo "    curl -O https://downloads.wordpress.org/plugin/${PLUGIN_NAME}${VERSION_STRING}.zip && \\" >> $DOCKERFILE_PATH
        echo "    unzip ${PLUGIN_NAME}${VERSION_STRING}.zip && rm ${PLUGIN_NAME}${VERSION_STRING}.zip" >> $DOCKERFILE_PATH
        
        echo "✅ Added $PLUGIN_NAME to Dockerfile"
        echo "📝 Remember to: git add Dockerfile && git commit && git push"
        ;;
        
    "remove")
        echo "🚧 Remove functionality not yet implemented"
        echo "Manually edit Dockerfile to remove plugins"
        ;;
        
    "list")
        echo "📦 Current plugins in Dockerfile:"
        grep -A1 "curl.*downloads.wordpress.org/plugin" $DOCKERFILE_PATH | grep curl | sed 's/.*plugin\///' | sed 's/\..*//'
        ;;
        
    "update-all")
        echo "🔄 Checking for plugin updates..."
        echo "🚧 This feature requires wp-cli integration (coming soon)"
        ;;
        
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac

echo ""
echo "💡 Tip: Test plugin compatibility in WordPress admin first,"
echo "   then add the working version here for permanent installation."