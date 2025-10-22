.PHONY: help start stop restart build install shell logs backup cleanup status recipe-list

# Default target
help:
	@echo "Drupal 11 with Recipes - Makefile Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  start         - Start Docker containers"
	@echo "  stop          - Stop Docker containers"
	@echo "  restart       - Restart Docker containers"
	@echo "  build         - Build Docker images"
	@echo "  install       - Install Drupal 11"
	@echo "  shell         - Access Drupal container shell"
	@echo "  logs          - View container logs"
	@echo "  backup        - Backup database"
	@echo "  cleanup       - Remove containers and volumes (WARNING)"
	@echo "  status        - Show container status"
	@echo "  recipe-list   - List available core recipes"
	@echo "  recipe-apply  - Apply a recipe (use: make recipe-apply RECIPE=article_core)"
	@echo "  cache-clear   - Clear Drupal cache"
	@echo "  composer-install - Run composer install in container"
	@echo "  phpinfo       - Display PHP info"

# Start containers
start:
	@echo "Starting containers..."
	docker-compose up -d
	@echo "Waiting for MySQL to be ready..."
	@sleep 30
	@echo "Containers started successfully!"
	@echo "Access Drupal at: http://localhost:8080"
	@echo "Access phpMyAdmin at: http://localhost:8081"

# Stop containers
stop:
	@echo "Stopping containers..."
	docker-compose stop
	@echo "Containers stopped"

# Restart containers
restart: stop start

# Build images
build:
	@echo "Building Docker images..."
	docker-compose build
	@echo "Build complete"

# Install Drupal
install:
	@echo "Installing Drupal 11..."
	docker exec -it drupal11 bash -c " \
		cd /var/www/html && \
		rm -rf * && \
		composer create-project drupal/recommended-project:^11 /tmp/drupal && \
		mv /tmp/drupal/* /var/www/html/ && \
		mv /tmp/drupal/.* /var/www/html/ 2>/dev/null || true && \
		rm -rf /tmp/drupal && \
		chown -R www-data:www-data /var/www/html && \
		chmod -R 755 /var/www/html \
	"
	@echo "Drupal installed! Visit http://localhost:8080 to complete setup"
	@echo "Database credentials: drupal/drupal/drupal on host 'mysql'"

# Access shell
shell:
	docker exec -it drupal11 bash

# View logs
logs:
	docker-compose logs -f

# Backup database
backup:
	@echo "Creating database backup..."
	docker exec drupal11_mysql mysqldump -u drupal -pdrupal drupal > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "Backup created"

# Cleanup (WARNING: Deletes all data)
cleanup:
	@echo "WARNING: This will delete all containers and data!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	docker-compose down -v
	@echo "Cleanup complete"

# Show status
status:
	docker-compose ps

# List core recipes
recipe-list:
	@docker exec drupal11 bash -c "ls -la /var/www/html/web/core/recipes/"

# Apply recipe (usage: make recipe-apply RECIPE=article_core)
recipe-apply:
ifndef RECIPE
	@echo "Error: Please specify RECIPE variable"
	@echo "Usage: make recipe-apply RECIPE=article_core"
	@exit 1
endif
	@echo "Applying recipe: $(RECIPE)"
	docker exec -it drupal11 bash -c " \
		cd /var/www/html/web && \
		php core/scripts/drupal recipe ../core/recipes/$(RECIPE) && \
		../vendor/bin/drush cr \
	"
	@echo "Recipe applied successfully!"

# Clear cache
cache-clear:
	@echo "Clearing Drupal cache..."
	docker exec drupal11 drush cr
	@echo "Cache cleared"

# Run composer install
composer-install:
	@echo "Running composer install..."
	docker exec drupal11 bash -c "cd /var/www/html && composer install"
	@echo "Composer install complete"

# Display PHP info
phpinfo:
	docker exec drupal11 php -i

# Quick test
test:
	@echo "Testing containers..."
	@docker-compose ps
	@echo ""
	@echo "Testing Drupal container..."
	@docker exec drupal11 php --version
	@echo ""
	@echo "Testing Composer..."
	@docker exec drupal11 composer --version
	@echo ""
	@echo "Testing Drush..."
	@docker exec drupal11 drush --version
	@echo ""
	@echo "All tests passed!"
