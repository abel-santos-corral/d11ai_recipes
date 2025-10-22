FROM drupal:11-apache

# Install PHP extensions, tools, and MySQL client
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    vim \
    wget \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libwebp-dev \
    libpq-dev \
    libzip-dev \
    default-mysql-client && \
    docker-php-ext-configure gd \
        --with-jpeg \
        --with-freetype \
        --with-webp && \
    docker-php-ext-install -j$(nproc) gd pdo pdo_mysql pdo_pgsql zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Install Drush globally
RUN composer global require drush/drush:^13 && \
    ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

# Set working directory
WORKDIR /opt/drupal

# Create recipes directory
RUN mkdir -p /opt/drupal/recipes

# Permissions
RUN chown -R www-data:www-data /opt/drupal && \
    chmod -R 755 /opt/drupal

# Expose port 80 for Apache
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
