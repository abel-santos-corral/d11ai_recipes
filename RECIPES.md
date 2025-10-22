# Complete Guide to Drupal Recipes

This guide covers everything you need to know about working with Drupal Recipes.

## 📖 What are Drupal Recipes?

Recipes are experimental features introduced in Drupal 10.3 and Drupal 11 that allow you to bundle modules, configuration, and content into reusable packages that can be applied to a Drupal site at any time during its lifecycle. They automate module installation and configuration by creating scripts that can install modules and themes and set up configuration on an existing Drupal installation.

### Key Features

- **Composable**: Mix and match recipes to build exactly what you need
- **Ephemeral**: Once applied, recipes can be safely removed - the configuration stays
- **Flexible**: Apply at any point in a site's lifecycle
- **Modular**: Avoid bloat by installing only what you need

## 🔧 Core Recipes in Drupal 11

Drupal 11 ships with several built-in recipes located in `web/core/recipes/`:

### Content Types
- **article_core** - Article content type with image field
- **page_core** - Basic page content type

### Media Types
- **audio_media_type** - Audio file handling
- **document_media_type** - Document uploads (PDF, DOC, etc.)
- **image_media_type** - Image handling
- **remote_video_media_type** - Embed YouTube, Vimeo videos
- **video_media_type** - Video file uploads

### Taxonomy
- **tags_taxonomy** - Basic tagging system

### Roles & Workflows
- **administrator_role** - Administrator role configuration
- **content_editor_role** - Content editor permissions
- **editorial_workflow** - Content moderation workflow

### Other
- **basic_block_type** - Custom block types
- **contact_form** - Site contact form
- **standard** - Complete standard installation profile as recipes

## 🎯 Applying Recipes

### Prerequisites

For Drupal 11.2+, recipe support is already configured. For earlier versions, configure Composer:

```bash
cd /var/www/html
composer config allow-plugins.drupal/core-recipe-unpack true
composer require drupal/core-recipe-unpack
composer require composer/installers:^2.3
composer config --merge --json extra.installer-paths '{"recipes/{$name}":["type:drupal-recipe"]}'
```

### Apply a Core Recipe

Recipes are applied from your webroot (typically /web or /docroot):

```bash
# Navigate to webroot
cd /var/www/html/web

# Apply recipe
php core/scripts/drupal recipe ../core/recipes/article_core

# Or using Drush
drush recipe ../core/recipes/article_core

# Clear cache
drush cr
```

### Apply Multiple Recipes

```bash
cd /var/www/html/web

# Apply several recipes at once
php core/scripts/drupal recipe ../core/recipes/article_core
php core/scripts/drupal recipe ../core/recipes/page_core
php core/scripts/drupal recipe ../core/recipes/tags_taxonomy
php core/scripts/drupal recipe ../core/recipes/image_media_type

drush cr
```

## 📦 Installing Community Recipes

### Finding Recipes

Browse available recipes:
- [Drupal Recipes Cookbook](https://www.drupal.org/docs/extending-drupal/contributed-modules/contributed-module-documentation/distributions-and-recipes-initiative/recipes-cookbook)
- [Drupal.org Projects](https://www.drupal.org/project/project_module?f%5B2%5D=sm_field_project_type%3Afull&f%5B3%5D=drupal_core%3A11)

### Popular Community Recipes

Community recipes include site starters, admin experiences, events management, and specialized features:

```bash
# Gin Admin Experience
composer require kanopi/gin-admin-experience
cd web && php core/scripts/drupal recipe ../recipes/gin-admin-experience

# Events (from Smart Date)
composer require drupal_recipes/events
cd web && php core/scripts/drupal recipe ../recipes/events

# Password Policy (90 days)
composer require kanopi/password-policy-90-days
cd web && php core/scripts/drupal recipe ../recipes/password-policy-90-days
```

## 🏗️ Creating Custom Recipes

### Basic Recipe Structure

A recipe needs only a folder with the recipe's name containing a recipe.yml file:

```
recipes/
└── my-recipe/
    ├── recipe.yml          # Required
    ├── config/             # Optional - configuration files
    ├── content/            # Optional - default content
    ├── composer.json       # Optional - dependencies
    ├── README.md          # Recommended
    └── LICENSE.md         # Recommended
```

### Example: Simple Recipe

Create `recipes/blog-setup/recipe.yml`:

```yaml
name: 'Blog Setup'
description: 'Complete blog configuration with common modules'
type: 'Site'

# Install modules
install:
  - views
  - admin_toolbar
  - admin_toolbar_tools
  - pathauto
  - metatag
  - redirect

# Import configuration
config:
  import:
    admin_toolbar: '*'
    pathauto: '*'
```

### Example: Recipe with Configuration

Create `recipes/seo-setup/recipe.yml`:

```yaml
name: 'SEO Setup'
description: 'SEO tools and configuration'
type: 'Site'

install:
  - metatag
  - metatag_open_graph
  - metatag_twitter_cards
  - pathauto
  - redirect
  - simple_sitemap

config:
  import:
    metatag: '*'
    simple_sitemap: '*'
  
  actions:
    # Configure pathauto patterns
    pathauto.pattern.article:
      createIfNotExists:
        id: article
        label: 'Article'
        type: 'canonical_entities:node'
        pattern: '/blog/[node:title]'
```

### Example: Recipe with Dependencies

Create `recipes/event-site/recipe.yml`:

```yaml
name: 'Event Site'
description: 'Complete event website setup'
type: 'Site'

# Depend on other recipes
recipes:
  - core/recipes/page_core
  - core/recipes/image_media_type
  - core/recipes/tags_taxonomy

# Install additional modules
install:
  - views
  - calendar
  - smart_date
  - address
  - geofield

# Create event content type via config
config:
  import:
    node.type.event: 'config/node.type.event.yml'
    field.storage.node.field_event_date: 'config/field.storage.node.field_event_date.yml'
    field.field.node.event.field_event_date: 'config/field.field.node.event.field_event_date.yml'
```

### Example: Recipe with Content

Create default content in `recipes/demo-content/content/`:

```yaml
# content/node.article.demo1.yml
_meta:
  entity_type: node
  bundle: article
  default_langcode: en

title: 'Welcome to Our Blog'
body:
  - value: |
      <p>This is a demo article created by the recipe.</p>
    format: basic_html
status: true
promote: true
uid: 1
```

## 🔄 Recipe Input (Drupal 11.1+)

Recipes can accept input from the command line and use replacement tokens in config actions:

```yaml
name: 'Contact Form with Custom Recipient'
description: 'Sets up contact form with specified email'

input:
  recipient:
    data_type: email
    description: 'Email address for form submissions'
    prompt:
      method: ask
      arguments:
        question: 'What email should receive feedback?'
    default: 'webmaster@example.com'

config:
  actions:
    contact.form.feedback:
      simple_config_update:
        recipients: '${recipient}'
```

Apply with input:

```bash
php core/scripts/drupal recipe ../recipes/contact-custom --input.recipient=admin@example.com
```

## 📋 Recipe Best Practices

### 1. Keep Recipes Focused

Each recipe should do one thing well:

```yaml
# Good: Focused recipe
name: 'SEO Basics'
install:
  - metatag
  - pathauto

# Less ideal: Too broad
name: 'Everything You Need'
install:
  - metatag
  - pathauto
  - views
  - admin_toolbar
  - # 50 more modules...
```

### 2. Use Recipe Dependencies

Build on existing recipes:

```yaml
recipes:
  - core/recipes/article_core
  - core/recipes/tags_taxonomy
  - ../other-recipe/recipe.yml
```

### 3. Document Your Recipes

Include README.md:

```markdown
# My Recipe

## What it does
- Installs X, Y, Z
- Configures A, B, C

## Usage
\`\`\`bash
php core/scripts/drupal recipe ../recipes/my-recipe
\`\`\`

## After Installation
1. Configure settings at /admin/config/...
2. Create your first content at /node/add/...
```

### 4. Version Control

Use semantic versioning in composer.json:

```json
{
  "name": "myorg/my-recipe",
  "type": "drupal-recipe",
  "description": "My awesome recipe",
  "version": "1.0.0",
  "require": {
    "drupal/core": "^11",
    "drupal/views": "^1.0"
  }
}
```

## 🧪 Testing Recipes

### Test on Fresh Installation

```bash
# Start fresh Drupal
./setup.sh cleanup
./setup.sh start
./setup.sh install

# Install and test your recipe
docker exec -it drupal11 bash
cd /var/www/html/web
php core/scripts/drupal recipe ../recipes/your-recipe -v
drush cr

# Verify changes
drush pml | grep [module-name]
drush config:get [config-name]
```

### Automated Testing

Create a test script:

```bash
#!/bin/bash
# test-recipe.sh

set -e

echo "Testing recipe..."

# Apply recipe
php core/scripts/drupal recipe ../recipes/my-recipe -v

# Check if module is enabled
if drush pml --status=enabled | grep -q "my_module"; then
    echo "✓ Module installed"
else
    echo "✗ Module not found"
    exit 1
fi

# Check configuration
if drush config:get my_module.settings | grep -q "expected_value"; then
    echo "✓ Configuration correct"
else
    echo "✗ Configuration incorrect"
    exit 1
fi

echo "All tests passed!"
```

## 🚀 Advanced Recipe Patterns

### Config Actions

```yaml
config:
  actions:
    # Create if doesn't exist
    node.type.custom:
      createIfNotExists:
        id: custom
        label: 'Custom Type'
    
    # Grant permissions
    user.role.editor:
      grantPermissions:
        - 'create custom content'
        - 'edit any custom content'
    
    # Simple config update
    system.site:
      simple_config_update:
        name: 'My Awesome Site'
        slogan: 'Built with Recipes'
```

### Conditional Logic (using multiple recipes)

```yaml
# recipes/site-base/recipe.yml
name: 'Site Base'
# Base configuration

# recipes/site-with-events/recipe.yml
name: 'Site with Events'
recipes:
  - ../site-base
install:
  - calendar
  - smart_date

# recipes/site-with-shop/recipe.yml
name: 'Site with Shop'
recipes:
  - ../site-base
install:
  - commerce
  - commerce_cart
```

## 📚 Additional Resources

- [Official Drupal Recipes Documentation](https://www.drupal.org/docs/extending-drupal/drupal-recipes)
- [Recipes Initiative Project](https://www.drupal.org/project/distributions_recipes)
- [Recipe Developer Guide](https://project.pages.drupalcode.org/distributions_recipes/)
- [DrupalCon Presentations on Recipes](https://www.youtube.com/results?search_query=drupalcon+recipes)

## 🤔 Common Questions

### Can I uninstall a recipe?

No, recipes are applied once and their results become part of your site. You can manually uninstall modules and remove configuration that was created by the recipe.

### Can recipes update existing configuration?

Yes, using config actions in the recipe.yml file.

### Are recipes the same as distributions?

No, distributions are full Drupal installations with specific purposes. Recipes are more modular and can be applied to any existing Drupal site.

### Can I use recipes in production?

Yes, but note they are still experimental in Drupal 11. Test thoroughly before using in production.

### How do I share my recipe?

Create a composer package and publish it on Drupal.org or Packagist.

---

**Happy recipe cooking!** 🍳
