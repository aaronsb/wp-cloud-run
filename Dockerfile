FROM wordpress:6.8.3-apache

# Install required tools for plugin management
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

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

# Create staging directory for our plugins
RUN mkdir -p /usr/src/wordpress-plugins /usr/src/wordpress-themes

# Remove: hello-dolly from source
RUN rm -f /usr/src/wordpress/wp-content/plugins/hello.php

# Plugin: wp-stateless (WordPress.org)
RUN cd /usr/src/wordpress-plugins && \
    curl -sLO https://downloads.wordpress.org/plugin/wp-stateless.latest-stable.zip && \
    unzip -q wp-stateless.latest-stable.zip && \
    rm wp-stateless.latest-stable.zip

# Plugin: akismet (WordPress.org) - Update to latest
RUN cd /usr/src/wordpress-plugins && \
    curl -sLO https://downloads.wordpress.org/plugin/akismet.latest-stable.zip && \
    unzip -q akismet.latest-stable.zip && \
    rm akismet.latest-stable.zip && \
    rm -rf /usr/src/wordpress/wp-content/plugins/akismet

# Plugin: wordpress-mcp (GitHub: Automattic/wordpress-mcp)
RUN cd /usr/src/wordpress-plugins && \
    git clone --depth 1 --branch trunk https://github.com/Automattic/wordpress-mcp.git wordpress-mcp && \
    rm -rf wordpress-mcp/.git && \
    cd wordpress-mcp && \
    if [ -f composer.json ]; then composer install --no-dev --optimize-autoloader; fi

# Plugin: wp-feature-api (GitHub: Automattic/wp-feature-api)
RUN cd /usr/src/wordpress-plugins && \
    git clone --depth 1 --branch trunk https://github.com/Automattic/wp-feature-api.git wp-feature-api && \
    rm -rf wp-feature-api/.git && \
    cd wp-feature-api && \
    if [ -f composer.json ]; then composer install --no-dev --optimize-autoloader; fi

# Plugin: merpress (WordPress.org)
RUN cd /usr/src/wordpress-plugins && \
    curl -sLO https://downloads.wordpress.org/plugin/merpress.latest-stable.zip && \
    unzip -q merpress.latest-stable.zip && \
    rm merpress.latest-stable.zip

# Theme: twentytwentyfour
RUN cd /usr/src/wordpress-themes && \
    curl -sLO https://downloads.wordpress.org/theme/twentytwentyfour.latest-stable.zip && \
    unzip -q twentytwentyfour.latest-stable.zip && \
    rm twentytwentyfour.latest-stable.zip

# Custom plugins (local)
COPY custom-plugins/astral-screensaver /usr/src/wordpress-plugins/astral-screensaver

# Copy all plugins and themes to WordPress source directory
RUN cp -r /usr/src/wordpress-plugins/* /usr/src/wordpress/wp-content/plugins/ && \
    cp -r /usr/src/wordpress-themes/* /usr/src/wordpress/wp-content/themes/ && \
    chown -R www-data:www-data /usr/src/wordpress/wp-content/

# Create mu-plugins directory and copy auto-activation plugin
RUN mkdir -p /usr/src/wordpress/wp-content/mu-plugins
COPY config/mu-plugins/auto-activate-plugins.php /usr/src/wordpress/wp-content/mu-plugins/

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${PORT}/wp-admin/install.php || exit 1

EXPOSE ${PORT}