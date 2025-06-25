<?php
// Test script to check what plugins are actually on disk
$plugins_dir = '/var/www/html/wp-content/plugins';
echo "<h1>Plugins Directory Contents</h1>\n";
echo "<pre>\n";
echo "Directory: $plugins_dir\n\n";

if (is_dir($plugins_dir)) {
    $dirs = scandir($plugins_dir);
    foreach ($dirs as $dir) {
        if ($dir != '.' && $dir != '..') {
            $full_path = $plugins_dir . '/' . $dir;
            $type = is_dir($full_path) ? 'DIR' : 'FILE';
            echo "$type: $dir\n";
            if ($type === 'DIR') {
                // Check for main plugin file
                $plugin_files = glob($full_path . '/*.php');
                foreach ($plugin_files as $file) {
                    if (strpos(file_get_contents($file), 'Plugin Name:') !== false) {
                        echo "  → Main plugin file: " . basename($file) . "\n";
                        break;
                    }
                }
            }
        }
    }
} else {
    echo "ERROR: Plugins directory not found!\n";
}

echo "\n\nPHP Working Directory: " . getcwd() . "\n";
echo "WordPress Version: " . get_bloginfo('version') . "\n";
echo "</pre>";
?>