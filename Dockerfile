FROM drupal:11-apache

# Install additional PHP extensions and tools
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
    && docker-php-ext-configure gd \
        --with-jpeg \
        --with-freetype \
        --with-webp \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql pdo_pgsql zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Install Drush globally
RUN composer global require drush/drush:^13 \
    && ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

# Set working directory
WORKDIR /var/www/html

# Create recipes directory
RUN mkdir -p /var/www/html/recipes

# Set proper permissions (including files folder)
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose port 80
EXPOSE 80
