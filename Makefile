# FreshBox SpA — Arquitectura Cloud EP1 (ARY1102)
# Atajos para el ciclo de vida de la infraestructura y del entorno local.

.PHONY: help up up-rapido check demo down local local-down

help: ## Muestra esta ayuda
	@echo "FreshBox SpA · Arquitectura Cloud EP1"
	@echo
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  make %-12s %s\n", $$1, $$2}'
	@echo

up: ## Despliega toda la infraestructura en AWS (~18 min)
	@./up.sh

up-rapido: ## Despliega sin reconstruir las imágenes de ECR (~7 min)
	@./up.sh --sin-imagenes

check: ## Verifica stacks, targets healthy y el catálogo por el balanceador
	@./infra/verify.sh --esperar

demo: ## Recorrido de demostración completo (red, seguridad, HA, CRUD, respaldo)
	@./infra/demo.sh todo

down: ## Elimina toda la infraestructura de AWS
	@./infra/teardown.sh

local: ## Levanta la aplicación en local con Docker Compose (sin AWS)
	@cd codigo && docker compose up -d --build && docker compose ps
	@echo
	@echo "  Frontend  http://localhost:8080"
	@echo "  API       http://localhost:8080/api/products"

local-down: ## Detiene el entorno local y borra el volumen de la base
	@cd codigo && docker compose down -v
