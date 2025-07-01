<?php
/**
 * Plugin Name: Auto-activate Required Plugins
 * Description: Automatically activates required plugins on every load
 * Version: 2.0
 */

// Only run in admin
if (!is_admin()) {
    return;
}

add_action('admin_init', function() {
    $required_plugins = [
        'akismet/akismet.php',
        'wp-stateless/wp-stateless.php', 
        'wordpress-mcp/wordpress-mcp.php',
        'wp-feature-api/wp-feature-api.php',
        'merpress/merpress.php'
    ];

    $activated = [];
    $already_active = [];
    
    foreach ($required_plugins as $plugin) {
        if (file_exists(WP_PLUGIN_DIR . '/' . $plugin)) {
            if (!is_plugin_active($plugin)) {
                activate_plugin($plugin);
                $activated[] = $plugin;
            } else {
                $already_active[] = $plugin;
            }
        }
    }

    // Show admin notice only if we activated something new
    if (!empty($activated)) {
        add_action('admin_notices', function() use ($activated) {
            echo '<div class="notice notice-success"><p>Auto-activated plugins: ' . 
                 implode(', ', array_map('basename', $activated)) . '</p></div>';
        });
    }
});