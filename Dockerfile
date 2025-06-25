FROM wordpress:6.8.1-apache

# Install required tools for plugin management
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Configure Apache to use Cloud Run's PORT environment variable
RUN sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf && \
    sed -i 's/:80/:${PORT}/g' /etc/apache2/sites-available/000-default.conf

# Install additional PHP extensions for better WordPress performance
RUN docker-php-ext-install opcache

# Configure opcache for production
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Set recommended PHP.ini settings
RUN { \
    echo 'memory_limit=256M'; \
    echo 'upload_max_filesize=64M'; \
    echo 'post_max_size=64M'; \
    echo 'max_execution_time=600'; \
    echo 'max_input_time=600'; \
    } > /usr/local/etc/php/conf.d/cloud-run-php.ini

# Copy custom wp-config.php if it exists
COPY config/wp-config.php /var/www/html/wp-config.php

# Copy and apply security configuration
COPY config/security.conf /etc/apache2/conf-available/security.conf
RUN a2enconf security && \
    a2enmod headers rewrite

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

# Remove: hello-dolly
RUN rm -rf /var/www/html/wp-content/plugins/hello-dolly

# Plugin: wp-stateless (WordPress.org)
RUN cd /var/www/html/wp-content/plugins && \
    curl -sLO https://downloads.wordpress.org/plugin/wp-stateless.latest-stable.zip && \
    unzip -q wp-stateless.latest-stable.zip && \
    rm wp-stateless.latest-stable.zip && \
    chown -R www-data:www-data wp-stateless

# Plugin: akismet (WordPress.org)
RUN cd /var/www/html/wp-content/plugins && \
    curl -sLO https://downloads.wordpress.org/plugin/akismet.latest-stable.zip && \
    unzip -q akismet.latest-stable.zip && \
    rm akismet.latest-stable.zip && \
    chown -R www-data:www-data akismet

# Plugin: wordpress-mcp (GitHub: Automattic/wordpress-mcp)
RUN cd /var/www/html/wp-content/plugins && \
    git clone --depth 1 --branch trunk https://github.com/Automattic/wordpress-mcp.git wordpress-mcp && \
    rm -rf wordpress-mcp/.git && \
    chown -R www-data:www-data wordpress-mcp

# Plugin: wp-feature-api (GitHub: Automattic/wp-feature-api)
RUN cd /var/www/html/wp-content/plugins && \
    git clone --depth 1 --branch trunk https://github.com/Automattic/wp-feature-api.git wp-feature-api && \
    rm -rf wp-feature-api/.git && \
    chown -R www-data:www-data wp-feature-api

# Theme: twentytwentyfour
RUN cd /var/www/html/wp-content/themes && \
    curl -sLO https://downloads.wordpress.org/theme/twentytwentyfour.latest-stable.zip && \
    unzip -q twentytwentyfour.latest-stable.zip && \
    rm twentytwentyfour.latest-stable.zip && \
    chown -R www-data:www-data twentytwentyfour

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html/wp-content && \
    find /var/www/html/wp-content -type d -exec chmod 755 {} \; && \
    find /var/www/html/wp-content -type f -exec chmod 644 {} \;

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${PORT}/wp-admin/install.php || exit 1

EXPOSE ${PORT}