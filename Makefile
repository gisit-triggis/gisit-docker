APP_DIR := src/gisit-backend
FRONT_DIR := src/gisit-frontend

all: install

init:
	@cd src && \
	git clone https://github.com/gisit-triggis/gisit-backend && \
	git clone https://github.com/gisit-triggis/gisit-realtime-backend && \
	git clone https://github.com/gisit-triggis/gisit-ai-backend && \
	git clone https://github.com/gisit-triggis/gisit-frontend

install:
	@echo "Установка зависимостей Laravel в $(APP_DIR)..."
	@cd $(APP_DIR) && composer install
	@cd $(FRONT_DIR) && yarn install && yarn run build

migrate:
	@echo "Выполнение миграций..."
	@docker compose exec -T backend php artisan migrate --force
	@docker compose exec -T backend php artisan clickhouse:migrate --force

migrate-fresh:
	@echo "Выполнение полных миграций..."
	@docker compose exec -T backend php artisan migrate:fresh --force
	@docker compose exec -T backend php artisan clickhouse:migrate --force

nginx:
	@echo "Перезапуск nginx..."
	@docker compose up -d --force-recreate nginx

backend:
	@echo "Ребилд backend..."
	@docker compose up -d --build --force-recreate backend

pull-backend:
	@echo "Пуллим backend..."
	@cd ./src/gisit-backend && git pull > .last-pull.log

	@echo "Анализ изменений..."

	@if grep -q "composer.json" ./src/gisit-backend/.last-pull.log; then \
		echo "Установка зависимостей..."; \
		cd ./src/gisit-backend && composer install; \
	fi

	@if grep -q "database/migrations/" ./src/gisit-backend/.last-pull.log; then \
		echo "Мигрирование..."; \
		make backend; \
		make migrate; \
	else \
		echo "Обновления не требуют миграций."; \
		make backend; \
	fi

optimize:
	@echo "Оптимизируем backend..."
	@docker compose exec -it backend php artisan optimize

realtime-backend:
	@echo "Ребилд realtime-backend..."
	@docker compose up -d --build --force-recreate realtime-backend

pull-realtime-backend:
	@echo "Пуллим realtime-backend..."
	@cd ./src/gisit-realtime-backend && git pull > .last-pull.log

	@echo "Анализ изменений..."

	echo "Обновления не требуют миграций."; \
	make realtime-backend; \

ai-backend:
	@echo "Ребилд ai-backend..."
	@docker compose up -d --build --force-recreate ai-backend

pull-ai-backend:
	@echo "Пуллим ai-backend..."
	@cd ./src/gisit-ai-backend && git pull > .last-pull.log

	@echo "Анализ изменений..."

	echo "Обновления не требуют миграций."; \
	make ai-backend; \

check-backend-logs:
	@echo "Читаем логи..."
	@docker compose exec -it backend cat /var/www/storage/logs/octane.log

down:
	@echo "Вырубаем контейнеры..."
	@docker compose down

up:
	@echo "Врубаем контейнеры..."
	@docker compose up -d --remove-orphans

commit:
	@git add .
	@git commit -m "fix"
	@git push

.PHONY: all install migrate nginx backend pull-backend down realtime-backend pull-realtime-backend init commit
