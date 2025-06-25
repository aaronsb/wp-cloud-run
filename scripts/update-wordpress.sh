#!/bin/bash
# Script to update WordPress version in Docker image

echo "WordPress Update Script"
echo "======================"
echo ""

# Check current version in Dockerfile
CURRENT_VERSION=$(grep "^FROM wordpress:" Dockerfile | cut -d':' -f2 | cut -d'-' -f1)
echo "Current WordPress version: $CURRENT_VERSION"

# Get latest WordPress version from Docker Hub
echo "Checking Docker Hub for latest WordPress version..."
LATEST_VERSION=$(curl -s https://hub.docker.com/v2/repositories/library/wordpress/tags | jq -r '.results[] | select(.name | test("^[0-9]+\\.[0-9]+\\.[0-9]+-apache$")) | .name' | head -1 | cut -d'-' -f1)

if [ -z "$LATEST_VERSION" ]; then
    echo "Error: Could not fetch latest version from Docker Hub"
    exit 1
fi

echo "Latest WordPress version available: $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Already running the latest version!"
    exit 0
fi

echo ""
read -p "Update WordPress from $CURRENT_VERSION to $LATEST_VERSION? (y/N): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Update cancelled."
    exit 0
fi

# Create backup of Dockerfile
cp Dockerfile Dockerfile.backup

# Update Dockerfile
sed -i "s/FROM wordpress:${CURRENT_VERSION}-apache/FROM wordpress:${LATEST_VERSION}-apache/" Dockerfile

echo "Dockerfile updated!"
echo ""
echo "Next steps:"
echo "1. Test locally: docker-compose build && docker-compose up"
echo "2. Commit changes: git add Dockerfile && git commit -m \"Update WordPress to ${LATEST_VERSION}\""
echo "3. Push to trigger deployment: git push origin main"
echo ""
echo "IMPORTANT: After deployment, visit your site and:"
echo "- Check that everything works correctly"
echo "- Run any database updates if prompted by WordPress"
echo "- Test critical functionality (uploads, plugins, etc.)"