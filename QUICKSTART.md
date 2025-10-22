# Quick Start Guide - Drupal 11 with Recipes

Get up and running with Drupal 11 and Recipes in under 10 minutes!

## 🚀 Super Quick Setup

### Step 1: Prepare Project Directory

```bash
# Create project directory
mkdir drupal11-recipes && cd drupal11-recipes

# Create necessary files (copy from repository)
# - docker-compose.yml
# - Dockerfile
# - .gitignore
```

### Step 2: Start Docker

```bash
# Start containers (first time takes 2-3 minutes)
docker-compose up -d

# Check status
docker-compose ps

# Wait 30 seconds for MySQL to initialize
```

### Step 3: Install Drupal

**Option A: Using the helper script (recommended)**

```bash
# Make script executable
chmod +x setup.sh

# Install Drupal
./setup.sh install

# Visit http://localhost:8080 and complete installation
```

**Option B: Manual installation**

```bash
# Enter container
docker exec -it drupal11 bash

# Install Drupal
cd /var/www/html
rm -rf *
composer create-project drupal/recommended-project:^11 /tmp/drupal
mv /tmp/drupal/* .
mv /tmp/drupal/.* . 2>/dev/null || true
chown -R www-data:www-data /var/www/html

# Exit and visit http://localhost:8080
```

### Step 4: Complete Web Installation

Visit **http://localhost:8080** and:

1. Select language
2. Choose "Standard" or "Minimal" profile
3. Database settings:
   - Database: `drupal`
   - Username: `drupal`
   - Password: `drupal`
   - Host: `mysql` (click "Advanced" to see this field)
4. Configure site (admin user, site name, etc.)

### Step 5: Test Recipes

```bash
# Enter container
docker exec -it drupal11 bash

# Go to web root
cd /var/www/html/web

# List available recipes
ls -la core/recipes/

# Apply a recipe (e.g., article)
php core/scripts/drupal recipe ../core/recipes/article_core

# Clear cache
drush cr

# Exit
exit
```

Visit your site and check **Content → Add content** - you should see "Article" content type!

## 🎯 Common Commands

```bash
# Start
docker-compose up -d

# Stop
docker-compose stop

# Complete cleanup (removes data!)
docker-compose down -v

# View logs
docker-compose logs -f drupal

# Access shell
docker exec -it drupal11 bash

# Clear Drupal cache
docker exec -it drupal11 drush cr
```

## 🍳 Recipe Examples

### Apply Core Recipes

```bash
docker exec -it drupal11 bash -c "
  cd /var/www/html/web
  php core/scripts/drupal recipe ../core/recipes/article_core
  php core/scripts/drupal recipe ../core/recipes/page_core
  php core/scripts/drupal recipe ../core/recipes/tags_taxonomy
  drush cr
"
```

### Install Community Recipe

```bash
docker exec -it drupal11 bash -c "
  cd /var/www/html
  composer require drupal_recipes/events
  cd web
  php core/scripts/drupal recipe ../recipes/events
  drush cr
"
```

### Create Custom Recipe

```bash
# Enter container
docker exec -it drupal11 bash

# Create recipe directory
mkdir -p /var/www/html/recipes/my-blog
cd /var/www/html/recipes/my-blog

# Create recipe.yml
cat > recipe.yml << 'EOF'
name: 'My Blog Setup'
description: 'Blog with common modules'
type: 'Site'

install:
  - views
  - admin_toolbar
  - pathauto
  - metatag

config:
  import:
    admin_toolbar: '*'
EOF

# Apply it
cd /var/www/html/web
php core/scripts/drupal recipe ../recipes/my-blog
drush cr
```

## 📊 Useful URLs

- **Drupal Site**: http://localhost:8080
- **Admin**: http://localhost:8080/user/login
- **phpMyAdmin**: http://localhost:8081

## 🆘 Troubleshooting

### Can't access the site?

```bash
# Check if containers are running
docker-compose ps

# Restart
docker-compose restart
```

### Permission errors?

```bash
docker exec -it drupal11 chown -R www-data:www-data /var/www/html
```

### Recipe not applying?

```bash
# Make sure you're in the web directory
cd /var/www/html/web

# Try with verbose mode
php core/scripts/drupal recipe ../recipes/recipe-name -v
```

### Start fresh?

```bash
# Remove everything
docker-compose down -v

# Start again
docker-compose up -d
```

## ✅ Next Steps

1. ✨ Explore core recipes in `web/core/recipes/`
2. 📦 Install community recipes from [Drupal.org](https://www.drupal.org/docs/extending-drupal/drupal-recipes)
3. 🎨 Install a theme and customize
4. 🔧 Create your own recipes for common configurations
5. 📚 Read the [full README](README.md) for advanced features

## 🎉 Success Checklist

- [ ] Docker containers running
- [ ] Drupal installed and accessible at http://localhost:8080
- [ ] Can login as admin
- [ ] Applied at least one recipe successfully
- [ ] Cache cleared with `drush cr`

**Congratulations! You're ready to explore Drupal 11 with Recipes!** 🚀
