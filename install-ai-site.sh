#!/bin/bash

# AI Site Installation Script
# This script installs Drupal 11 with Standard profile and AI modules

set -e

echo "=================================================="
echo "AI Site Installation Script"
echo "=================================================="

# Configuration
CONTAINER_NAME="drupal11"
DRUPAL_ROOT="/var/www/html"
WEB_ROOT="${DRUPAL_ROOT}"
RECIPE_DIR="${DRUPAL_ROOT}/recipes/ai-site"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if container is running
check_container() {
    if ! docker ps | grep -q "${CONTAINER_NAME}"; then
        print_error "Container ${CONTAINER_NAME} is not running!"
        print_info "Start it with: docker-compose up -d"
        exit 1
    fi
    print_info "Container ${CONTAINER_NAME} is running"
}

# Function to wait for Drupal to be ready
wait_for_drupal() {
    print_info "Waiting for Drupal to be ready..."
    local max_attempts=60
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if docker exec ${CONTAINER_NAME} bash -c "cd ${DRUPAL_ROOT} && ./vendor/bin/drush status bootstrap" 2>/dev/null | grep -q 'Successful'; then
            print_info "Drupal is ready!"
            return 0
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done

    print_error "Drupal did not become ready in time"
    exit 1
}


# Function to install Drush if not present
install_drush() {
    print_info "Checking for Drush..."

    if docker exec ${CONTAINER_NAME} test -f ${DRUPAL_ROOT}/vendor/bin/drush 2>/dev/null; then
        print_info "Drush is already installed"
        return 0
    fi

    print_info "Installing Drush..."
    docker exec ${CONTAINER_NAME} bash -c "cd ${DRUPAL_ROOT} && composer require drush/drush --no-interaction"
    print_info "Drush installed successfully!"
}

# Function to install Drupal with Standard profile
install_drupal() {
    print_info "Installing Drupal with Standard profile..."

    # Check if already installed
    if docker exec ${CONTAINER_NAME} test -f ${WEB_ROOT}/sites/default/settings.php 2>/dev/null; then
        print_warning "Drupal appears to be already installed"
        read -p "Do you want to reinstall? This will delete all data! (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping Drupal installation"
            return 0
        fi

        # Drop existing database and recreate
        print_info "Cleaning up existing installation..."
        docker exec ${CONTAINER_NAME} bash -c "cd ${DRUPAL_ROOT} && \
            ./vendor/bin/drush sql:drop --yes 2>/dev/null || true"

        # Remove settings.php
        docker exec ${CONTAINER_NAME} bash -c "rm -f ${WEB_ROOT}/sites/default/settings.php"
    fi

    # Ensure Drush is installed
    install_drush

    # Install Drupal using Drush
    print_info "Running Drupal installation..."
    docker exec ${CONTAINER_NAME} bash -c "cd ${DRUPAL_ROOT} && \
        ./vendor/bin/drush site:install standard \
        --db-url='mysql://drupal:drupal@mysql/drupal?ssl-mode=DISABLED' \
        --site-name='AI Drupal Site' \
        --account-name=admin \
        --account-pass=admin \
        --yes"

    print_info "Drupal installed successfully!"
    print_info "Admin credentials: admin / admin"
}

# Function to install AI modules via Composer
install_ai_modules() {
    print_info "Installing AI modules via Composer..."

    docker exec ${CONTAINER_NAME} bash -c "cd ${DRUPAL_ROOT} && \
        composer require \
        drupal/ai:^1.0 \
        drupal/ai_provider_ollama:^1.0 \
        drupal/ai_provider_mistral:^1.0 \
        --no-interaction 2>&1 | grep -v 'Deprecation'"

    print_info "AI modules downloaded successfully!"
}

# Function to create recipe directory and files
create_recipe() {
    print_info "Creating AI site recipe..."

    # Create recipe directory
    docker exec ${CONTAINER_NAME} mkdir -p ${RECIPE_DIR}

    # Create recipe.yml
    docker exec ${CONTAINER_NAME} bash -c "cat > ${RECIPE_DIR}/recipe.yml << 'EOF'
name: 'AI Site Setup'
description: 'Complete AI-powered Drupal site with Ollama and Mistral providers'
type: 'Site'

# Install the AI module and its dependencies
install:
  - ai
  - ai_provider_ollama
  - ai_provider_mistral

# Import configuration for AI modules
config:
  import:
    ai: '*'
    ai_provider_ollama: '*'
    ai_provider_mistral: '*'
EOF"

    # Create composer.json
    docker exec ${CONTAINER_NAME} bash -c "cat > ${RECIPE_DIR}/composer.json << 'EOF'
{
  \"name\": \"myorg/ai-site-recipe\",
  \"description\": \"Recipe for AI-powered Drupal site with Ollama and Mistral\",
  \"type\": \"drupal-recipe\",
  \"license\": \"GPL-2.0-or-later\",
  \"require\": {
    \"drupal/core\": \"^11\",
    \"drupal/ai\": \"^1.0\",
    \"drupal/ai_provider_ollama\": \"^1.0\",
    \"drupal/ai_provider_mistral\": \"^1.0\"
  }
}
EOF"

    # Create README.md
    docker exec ${CONTAINER_NAME} bash -c "cat > ${RECIPE_DIR}/README.md << 'EOF'
# AI Site Recipe

This recipe sets up a Drupal 11 site with AI capabilities including:

- AI module for base AI functionality
- Ollama provider for local LLM integration
- Mistral provider for Mistral AI integration

## Usage

The recipe is automatically applied by the installation script.

## After Installation

1. Visit your site at http://localhost:8080
2. Login with admin / admin
3. Configure AI providers at /admin/config/ai
4. Configure Ollama at /admin/config/ai/provider/ollama
5. Configure Mistral at /admin/config/ai/provider/mistral

## Modules Installed

- ai
- ai_provider_ollama
- ai_provider_mistral
EOF"

    print_info "Recipe created successfully!"
}

# Function to apply recipe
apply_recipe() {
    print_info "Applying AI site recipe..."

    docker exec ${CONTAINER_NAME} bash -c "cd ${WEB_ROOT} && \
        php core/scripts/drupal recipe ../recipes/ai-site -v"

    print_info "Recipe applied successfully!"
}

# Function to clear cache
clear_cache() {
    print_info "Clearing Drupal cache..."

    docker exec ${CONTAINER_NAME} bash -c "cd ${WEB_ROOT} && \
        php core/scripts/drupal cache:rebuild"

    print_info "Cache cleared!"
}

# Function to verify installation
verify_installation() {
    print_info "Verifying installation..."

    echo ""
    print_info "Checking installed modules:"
    docker exec ${CONTAINER_NAME} bash -c "cd ${DRUPAL_ROOT} && \
        ./vendor/bin/drush pm:list --status=enabled --type=module | grep -i ai" || print_warning "No AI modules found in enabled list yet"

    echo ""
}

# Function to display final information
display_info() {
    echo ""
    echo "=================================================="
    print_info "Installation Complete!"
    echo "=================================================="
    echo ""
    echo "🌐 Site URL: http://localhost:8080"
    echo "👤 Username: admin"
    echo "🔑 Password: admin"
    echo ""
    echo "📦 Installed Modules:"
    echo "   - AI"
    echo "   - AI Provider Ollama"
    echo "   - AI Provider Mistral"
    echo ""
    echo "⚙️  Configuration URLs:"
    echo "   - AI Configuration: http://localhost:8080/admin/config/ai"
    echo "   - Ollama Provider: http://localhost:8080/admin/config/ai/provider/ollama"
    echo "   - Mistral Provider: http://localhost:8080/admin/config/ai/provider/mistral"
    echo ""
    echo "🗄️  Database Management: http://localhost:8081"
    echo ""
    echo "💡 Next Steps:"
    echo "   1. Visit http://localhost:8080 and login"
    echo "   2. Configure your AI providers"
    echo "   3. Test AI functionality"
    echo ""
    echo "=================================================="
    echo ""
}

# Main execution
main() {
    print_info "Starting AI Site Installation..."
    echo ""

    check_container
    install_drupal
    wait_for_drupal
    install_ai_modules
    create_recipe
    apply_recipe
    clear_cache
    verify_installation
    display_info

}

# Run main function
main