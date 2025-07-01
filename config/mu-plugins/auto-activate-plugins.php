<?php
/**
 * Plugin Name: Auto-activate Required Plugins
 * Description: Automatically activates required plugins on load
 * Version: 1.0
 */

// Only run in admin or if plugins need activation
if (!is_admin() && get_option('_plugins_activated', false)) {
    return;
}

add_action('admin_init', function() {
    // Skip if already activated
    if (get_option('_plugins_activated', false)) {
        return;
    }

    $required_plugins = [
        'akismet/akismet.php',
        'wp-stateless/wp-stateless.php', 
        'wordpress-mcp/wordpress-mcp.php',
        'wp-feature-api/wp-feature-api.php',
        'merpress/merpress.php'
    ];

    $activated = [];
    foreach ($required_plugins as $plugin) {
        if (file_exists(WP_PLUGIN_DIR . '/' . $plugin)) {
            activate_plugin($plugin);
            $activated[] = $plugin;
        }
    }

    // Mark as done
    if (!empty($activated)) {
        update_option('_plugins_activated', true);
        
        // Show admin notice
        add_action('admin_notices', function() use ($activated) {
            echo '<div class="notice notice-success"><p>Auto-activated plugins: ' . 
                 implode(', ', array_map('basename', $activated)) . '</p></div>';
        });
    }
});