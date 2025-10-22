#!/bin/bash

# Drupal 11 with Recipes - Setup Script
# This script helps automate common tasks

set -e

CONTAINER_NAME="drupal11"
WEB_ROOT="/var/www/html"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    print_success "Docker is running"
}

# Start containers
start_containers() {
    print_info "Starting Docker containers..."
    docker-compose up -d
    print_success "Containers started"
    print_info "Waiting for MySQL to be ready..."
    sleep 30
    print_success "Setup complete!"
    echo ""
    echo "Access your Drupal site at: http://localhost:8080"
    echo "Access phpMyAdmin at: http://localhost:8081"
}

# Stop containers
stop_containers() {
    print_info "Stopping Docker containers..."
    docker-compose stop
    print_success "Containers stopped"
}

# Restart containers
restart_containers() {
    stop_containers
    start_containers
}

# Remove everything (including volumes)
cleanup() {
    print_info "WARNING: This will remove all containers and data volumes!"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        docker-compose down -v
        print_success "Cleanup complete"
    else
        print_info "Cleanup cancelled"
    fi
}

# Install Drupal inside container
install_drupal() {
    print_info "Installing Drupal 11..."
    docker exec -it $CONTAINER_NAME bash -c "
        cd $WEB_ROOT
        rm -rf *
        composer create-project drupal/recommended-project:^11 /tmp/drupal
        mv /tmp/drupal/* $WEB_ROOT/
        mv /tmp/drupal/.* $WEB_ROOT/ 2>/dev/null || true
        rm -rf /tmp/drupal
        chown -R www-data:www-data $WEB_ROOT
        chmod -R 755 $WEB_ROOT
    "
    print_success "Drupal installed!"
    echo ""
    echo "Now visit http://localhost:8080 to complete the web installation"
    echo "Database credentials:"
    echo "  - Database: drupal"
    echo "  - Username: drupal"
    echo "  - Password: drupal"
    echo "  - Host: mysql"
}

# Configure recipes
configure_recipes() {
    print_info "Configuring Drupal for Recipes..."
    docker exec -it $CONTAINER_NAME bash -c "
        cd $WEB_ROOT
        composer config allow-plugins.drupal/core-recipe-unpack true
        composer require drupal/core-recipe-unpack
        composer require composer/installers:^2.3
        composer config --merge --json extra.installer-paths '{\"recipes/{\$name}\":[\"type:drupal-recipe\"]}'
    "
    print_success "Recipes configured!"
}

# Apply a recipe
apply_recipe() {
    if [ -z "$1" ]; then
        print_error "Please provide a recipe name or path"
        echo "Usage: ./setup.sh apply-recipe <recipe-name>"
        echo "Example: ./setup.sh apply-recipe article_core"
        exit 1
    fi
    
    print_info "Applying recipe: $1"
    docker exec -it $CONTAINER_NAME bash -c "
        cd $WEB_ROOT/web
        php core/scripts/drupal recipe $1
        ../vendor/bin/drush cr
    "
    print_success "Recipe applied successfully!"
}

# List core recipes
list_recipes() {
    print_info "Available core recipes:"
    docker exec -it $CONTAINER_NAME bash -c "
        cd $WEB_ROOT/web/core/recipes
        ls -1
    "
}

# Enter container shell
shell() {
    print_info "Entering container shell..."
    docker exec -it $CONTAINER_NAME bash
}

# Show logs
logs() {
    docker-compose logs -f
}

# Backup database
backup_db() {
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    print_info "Creating database backup: $BACKUP_FILE"
    docker exec drupal11_mysql mysqldump -u drupal -pdrupal drupal > "$BACKUP_FILE"
    print_success "Backup created: $BACKUP_FILE"
}

# Show help
show_help() {
    echo "Drupal 11 with Recipes - Setup Script"
    echo ""
    echo "Usage: ./setup.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start              - Start Docker containers"
    echo "  stop               - Stop Docker containers"
    echo "  restart            - Restart Docker containers"
    echo "  install            - Install Drupal 11 inside container"
    echo "  configure-recipes  - Configure Drupal for recipes"
    echo "  apply-recipe <name> - Apply a recipe (e.g., article_core)"
    echo "  list-recipes       - List available core recipes"
    echo "  shell              - Enter container shell"
    echo "  logs               - Show container logs"
    echo "  backup             - Backup database"
    echo "  cleanup            - Remove containers and volumes (WARNING: deletes data)"
    echo "  help               - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./setup.sh start"
    echo "  ./setup.sh install"
    echo "  ./setup.sh apply-recipe ../core/recipes/article_core"
    echo "  ./setup.sh shell"
}

# Main script logic
case "$1" in
    start)
        check_docker
        start_containers
        ;;
    stop)
        stop_containers
        ;;
    restart)
        restart_containers
        ;;
    install)
        install_drupal
        ;;
    configure-recipes)
        configure_recipes
        ;;
    apply-recipe)
        apply_recipe "$2"
        ;;
    list-recipes)
        list_recipes
        ;;
    shell)
        shell
        ;;
    logs)
        logs
        ;;
    backup)
        backup_db
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        if [ -z "$1" ]; then
            show_help
        else
            print_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
        fi
        ;;
esac
