#!/bin/bash
# Custom entrypoint to activate plugins after WordPress starts

# First, run the original WordPress entrypoint
docker-entrypoint.sh "$@" &
WORDPRESS_PID=$!

# Wait for WordPress to be ready
echo "Waiting for WordPress to initialize..."
sleep 10

# Check if we can connect to WordPress
if curl -f http://localhost:${PORT:-80}/wp-admin/install.php >/dev/null 2>&1; then
    echo "WordPress is ready, activating plugins..."
    
    # Create a PHP script to activate plugins
    cat > /tmp/activate-plugins.php << 'EOF'
<?php
// Load WordPress
define('WP_USE_THEMES', false);
require('/var/www/html/wp-load.php');

// Plugins to activate
$plugins_to_activate = [
    'akismet/akismet.php',
    'wp-stateless/wp-stateless.php',
    'wordpress-mcp/wordpress-mcp.php',
    'wp-feature-api/wp-feature-api.php'
];

// Get current active plugins
$active_plugins = get_option('active_plugins', []);
$activated = [];

// Activate each plugin if not already active
foreach ($plugins_to_activate as $plugin) {
    if (!in_array($plugin, $active_plugins)) {
        $active_plugins[] = $plugin;
        $activated[] = $plugin;
    }
}

// Update the option
if (!empty($activated)) {
    update_option('active_plugins', $active_plugins);
    echo "Activated plugins: " . implode(', ', $activated) . "\n";
} else {
    echo "All plugins already active\n";
}

// Remove Hello Dolly if present
$active_plugins = array_diff($active_plugins, ['hello.php']);
update_option('active_plugins', $active_plugins);
EOF

    # Run the activation script
    cd /var/www/html && php /tmp/activate-plugins.php
    rm /tmp/activate-plugins.php
else
    echo "WordPress not ready yet, skipping plugin activation"
fi

# Wait for the original WordPress process
wait $WORDPRESS_PID