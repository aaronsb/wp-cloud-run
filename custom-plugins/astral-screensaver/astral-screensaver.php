<?php
/**
 * Plugin Name: Astral Screensaver
 * Description: A contemplative canvas screensaver with floating particles, graph edges, and existential wisdom. Use the [astral-screensaver] shortcode.
 * Version: 0.4
 * Author: graph-attract.io
 */

if (!defined('ABSPATH')) exit;

function astral_screensaver_shortcode() {
    wp_enqueue_style(
        'astral-screensaver',
        plugin_dir_url(__FILE__) . 'style.css',
        [],
        '0.4'
    );
    wp_enqueue_script(
        'astral-screensaver',
        plugin_dir_url(__FILE__) . 'astral-screensaver.js',
        [],
        '0.4',
        true
    );

    return '<div id="astral-screensaver"></div>';
}
add_shortcode('astral-screensaver', 'astral_screensaver_shortcode');
