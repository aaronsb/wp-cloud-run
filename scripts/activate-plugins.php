<?php
/**
 * Auto-activate plugins defined in manifest
 * This runs during container startup
 */

// Required plugins to activate
$plugins_to_activate = [
    'akismet/akismet.php',
    'wp-stateless/wp-stateless.php',
    'wordpress-mcp/wordpress-mcp.php',
    'wp-feature-api/wp-feature-api.php'
];

// Get current active plugins
$active_plugins = get_option('active_plugins', []);

// Add our plugins if not already active
foreach ($plugins_to_activate as $plugin) {
    if (!in_array($plugin, $active_plugins)) {
        $active_plugins[] = $plugin;
    }
}

// Update the database
update_option('active_plugins', $active_plugins);

// Remove Hello Dolly if active
$active_plugins = array_diff($active_plugins, ['hello.php']);
update_option('active_plugins', $active_plugins);

echo "Plugins activated successfully\n";