<?php
/**
 * WordPress configuration for Google Cloud Run
 * 
 * This config file reads database credentials from environment variables
 * and handles Cloud Run specific settings like HTTPS detection
 */

// ** Database settings from environment variables ** //
define( 'DB_NAME', getenv('WORDPRESS_DB_NAME') ?: 'wordpress' );
define( 'DB_USER', getenv('WORDPRESS_DB_USER') ?: 'root' );
define( 'DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD') ?: '' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

// ** Cloud SQL Socket connection ** //
// If using Cloud SQL, the host will be in format: project:region:instance
// Cloud Run automatically provides the socket at /cloudsql/
$db_host = getenv('WORDPRESS_DB_HOST') ?: 'localhost';
if ( strpos( $db_host, ':' ) !== false && file_exists( '/cloudsql/' ) ) {
    define( 'DB_HOST', 'localhost:/cloudsql/' . $db_host );
} else {
    define( 'DB_HOST', $db_host );
}

// ** Authentication Unique Keys and Salts ** //
// Generate these from: https://api.wordpress.org/secret-key/1.1/salt/
// Or use environment variables for better security
define( 'AUTH_KEY',         getenv('WORDPRESS_AUTH_KEY') ?: 'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  getenv('WORDPRESS_SECURE_AUTH_KEY') ?: 'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    getenv('WORDPRESS_LOGGED_IN_KEY') ?: 'put your unique phrase here' );
define( 'NONCE_KEY',        getenv('WORDPRESS_NONCE_KEY') ?: 'put your unique phrase here' );
define( 'AUTH_SALT',        getenv('WORDPRESS_AUTH_SALT') ?: 'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', getenv('WORDPRESS_SECURE_AUTH_SALT') ?: 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   getenv('WORDPRESS_LOGGED_IN_SALT') ?: 'put your unique phrase here' );
define( 'NONCE_SALT',       getenv('WORDPRESS_NONCE_SALT') ?: 'put your unique phrase here' );

// ** WordPress Database Table prefix ** //
$table_prefix = getenv('WORDPRESS_TABLE_PREFIX') ?: 'wp_';

// ** Cloud Run HTTPS Detection ** //
// Cloud Run terminates SSL at the load balancer level
if ( isset( $_SERVER['HTTP_X_FORWARDED_PROTO'] ) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https' ) {
    $_SERVER['HTTPS'] = 'on';
}

// ** WordPress Debugging Mode ** //
define( 'WP_DEBUG', getenv('WORDPRESS_DEBUG') === 'true' );
define( 'WP_DEBUG_LOG', getenv('WORDPRESS_DEBUG') === 'true' );
define( 'WP_DEBUG_DISPLAY', false );

// ** Disable automatic updates in Cloud Run ** //
define( 'AUTOMATIC_UPDATER_DISABLED', true );
define( 'WP_AUTO_UPDATE_CORE', false );

// ** Memory Limits ** //
define( 'WP_MEMORY_LIMIT', '256M' );
define( 'WP_MAX_MEMORY_LIMIT', '512M' );

// ** File Permissions ** //
// Cloud Run filesystem is read-only except for /tmp
define( 'FS_METHOD', 'direct' );

// ** Multisite ** //
define( 'WP_ALLOW_MULTISITE', getenv('WORDPRESS_MULTISITE') === 'true' );

// ** Absolute path to the WordPress directory ** //
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

// ** Sets up WordPress vars and included files ** //
require_once ABSPATH . 'wp-settings.php';