FROM wordpress:6.5-apache

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

# Create uploads directory with proper permissions
RUN mkdir -p /var/www/html/wp-content/uploads && \
    chown -R www-data:www-data /var/www/html/wp-content

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${PORT}/wp-admin/install.php || exit 1

EXPOSE ${PORT}