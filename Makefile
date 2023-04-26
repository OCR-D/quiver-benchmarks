build:
	docker compose build

start:
	docker compose run -d app

prepare-default-gt:
	docker compose exec app bash scripts/prepare.sh

run:
	mkdir -p logs
	docker compose exec app quiver run-ocr > logs/run_$$(date +"%F-%H:%M:%S").log

stop:
	CONTAINER_ID=$$(docker ps | grep quiver | cut -d' ' -f1); docker container stop $$CONTAINER_ID && docker container remove $$CONTAINER_ID

clean-workspaces:
	docker compose exec app rm -rf workflows/workspaces

clean-results:
	docker compose exec app rm -rf workflows/nf-results workflows/results

clean: clean-workspaces clean-results
	@echo "Cleaning everything."