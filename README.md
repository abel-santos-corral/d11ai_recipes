# Drupal 11 with Recipes - Docker Setup

Complete Docker-based development environment for Drupal 11 with Recipes support.

## 📋 Prerequisites

- Docker installed ([Download Docker](https://www.docker.com/products/docker-desktop))
- Docker Compose installed (included with Docker Desktop)
- Git installed
- Basic command line knowledge

## 🚀 Quick Start

### 1. Clone or Create the Repository

```bash
# If starting fresh, create a new directory
mkdir drupal11-recipes-docker
cd drupal11-recipes-docker

# Initialize git repository
git init
```

### 2. Create Project Files

Create the following files in your project directory:
- `docker-compose.yml` (provided)
- `Dockerfile` (provided)
- `.gitignore` (provided below)

### 3. Start Docker Containers

```bash
# Build and start containers
docker-compose up -d

# Check if containers are running
docker-compose ps
```

Wait for MySQL to be healthy (about 30-60 seconds on first run).

### 4. Install Drupal 11

Access the Drupal container:

```bash
docker exec -it drupal11 bash
```

Inside the container, install Drupal using Composer:

```bash
# Remove default files
rm -rf /var/www/html/*

# Install Drupal 11 using Composer
composer create-project drupal/recommended-project:^11 /tmp/drupal
mv /tmp/drupal/* /var/www/html/
mv /tmp/drupal/.* /var/www/html/ 2>/dev/null || true
rm -rf /tmp/drupal

# Set permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
```

### 5. Install Drupal via Web Interface

Open your browser and go to: **http://localhost:8080**

Follow the installation wizard:
- **Language**: Choose your language
- **Profile**: Select "Standard" or "Minimal"
- **Database Configuration**:
  - Database type: MySQL, MariaDB, or equivalent
  - Database name: `drupal`
  - Database username: `drupal`
  - Database password: `drupal`
  - Advanced Options → Host: `mysql`

Complete the site configuration with your details.

## 🍳 Working with Recipes

### Configure Drupal for Recipes (Drupal 11.0-11.1)

If you're on Drupal 11.2+, skip this section. For earlier versions:

```bash
# Inside the container
cd /var/www/html

# Configure Composer for recipes
composer config allow-plugins.drupal/core-recipe-unpack true
composer require drupal/core-recipe-unpack
composer require composer/installers:^2.3
composer config --merge --json extra.installer-paths '{"recipes/{$name}":["type:drupal-recipe"]}'
```

### Explore Core Recipes

Drupal 11 comes with built-in recipes in `core/recipes/`:

```bash
# List available core recipes
ls -la web/core/recipes/
```

Core recipes include:
- `standard` - Standard Drupal installation features
- `administrator_role` - Admin role configuration
- `article_core` - Article content type
- `audio_media_type` - Audio media handling
- `basic_block_type` - Basic block type
- `contact_form` - Contact form functionality
- `content_editor_role` - Content editor role
- `document_media_type` - Document media handling
- `editorial_workflow` - Editorial workflow
- `image_media_type` - Image media handling
- `page_core` - Basic page content type
- `remote_video_media_type` - Remote video embedding
- `tags_taxonomy` - Tags taxonomy
- `video_media_type` - Video media handling

### Apply a Core Recipe

```bash
# Navigate to web root
cd /var/www/html/web

# Apply a recipe (example: article_core)
php core/scripts/drupal recipe ../core/recipes/article_core

# Clear cache
drush cr
```

### Install Community Recipes

Browse available recipes at: [Drupal Recipes Cookbook](https://www.drupal.org/docs/extending-drupal/contributed-modules/contributed-module-documentation/distributions-and-recipes-initiative/recipes-cookbook)

Example: Installing Events recipe:

```bash
cd /var/www/html

# Install a community recipe
composer require drupal_recipes/events

# Apply the recipe
cd web
php core/scripts/drupal recipe ../recipes/events

# Clear cache
drush cr
```

### Popular Community Recipes

```bash
# Install Gin Admin Experience
composer require kanopi/gin-admin-experience
cd web && php core/scripts/drupal recipe ../recipes/gin-admin-experience

# Install SEO Tools (example if available)
# composer require [recipe-package]
# cd web && php core/scripts/drupal recipe ../recipes/[recipe-name]
```

### Create Your Own Recipe

Create a custom recipe:

```bash
mkdir -p recipes/my-custom-recipe
cd recipes/my-custom-recipe
```

Create `recipe.yml`:

```yaml
name: 'My Custom Recipe'
description: 'A custom recipe for my Drupal site'
type: 'Site'

install:
  - views
  - admin_toolbar
  - pathauto

config:
  import:
    admin_toolbar: '*'
```

Apply your custom recipe:

```bash
cd /var/www/html/web
php core/scripts/drupal recipe ../recipes/my-custom-recipe
drush cr
```

## 🔧 Useful Commands

### Docker Management

```bash
# Start containers
docker-compose up -d

# Stop containers
docker-compose stop

# Stop and remove containers (keeps volumes)
docker-compose down

# Stop, remove containers AND volumes (complete cleanup)
docker-compose down -v

# View logs
docker-compose logs -f drupal

# Access Drupal container shell
docker exec -it drupal11 bash

# Access MySQL container
docker exec -it drupal11_mysql mysql -u drupal -pdrupal drupal
```

### Drupal/Drush Commands

```bash
# Inside the container
docker exec -it drupal11 bash

# Clear cache
drush cr

# Update database
drush updb

# Export configuration
drush cex

# Import configuration
drush cim

# Show Drupal status
drush status

# List installed modules
drush pml
```

### Backup and Restore

```bash
# Backup database
docker exec drupal11_mysql mysqldump -u drupal -pdrupal drupal > backup.sql

# Restore database
docker exec -i drupal11_mysql mysql -u drupal -pdrupal drupal < backup.sql

# Backup files
docker cp drupal11:/var/www/html/web/sites/default/files ./files-backup
```

## 🌐 Access Points

- **Drupal Site**: http://localhost:8080
- **phpMyAdmin**: http://localhost:8081
  - Username: `drupal`
  - Password: `drupal`

## 📁 Project Structure

```
drupal11-recipes-docker/
├── docker-compose.yml
├── Dockerfile
├── .gitignore
├── README.md
└── (Drupal files will be in Docker volumes)
```

## 🔐 Security Notes

**Important**: This setup is for development only!

For production:
- Change all default passwords
- Use environment variables for secrets
- Implement proper SSL/TLS
- Follow Drupal security best practices
- Regular updates and backups

## 🐛 Troubleshooting

### Container won't start
```bash
docker-compose down -v
docker-compose up -d --build
```

### Permission issues
```bash
docker exec -it drupal11 bash
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
```

### MySQL connection issues
```bash
# Check if MySQL is healthy
docker-compose ps

# View MySQL logs
docker-compose logs mysql
```

### Recipe application fails
```bash
# Make sure you're in the web directory
cd /var/www/html/web

# Try with verbose output
php core/scripts/drupal recipe ../recipes/[recipe-name] -v

# Clear cache after applying
drush cr
```

## 📚 Additional Resources

- [Drupal 11 Documentation](https://www.drupal.org/docs/11)
- [Drupal Recipes Documentation](https://www.drupal.org/docs/extending-drupal/drupal-recipes)
- [Recipes Cookbook](https://www.drupal.org/docs/extending-drupal/contributed-modules/contributed-module-documentation/distributions-and-recipes-initiative/recipes-cookbook)
- [Docker Documentation](https://docs.docker.com/)
- [Drush Commands](https://www.drush.org/latest/commands/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is open source. Drupal is licensed under GPL v2.

## ✨ What's Next?

After setting up:
1. Explore core recipes in `web/core/recipes/`
2. Install community recipes from Drupal.org
3. Create custom recipes for your project
4. Learn about [Drupal Starshot](https://www.drupal.org/about/starshot) initiative
5. Experiment with different recipe combinations

Happy Drupal development! 🎉
