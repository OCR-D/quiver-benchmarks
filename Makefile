build:
	docker compose build

start:
	docker compose run -d app

prepare-default-gt:
	docker compose exec app bash scripts/prepare.sh

run:
	if [ ! -d logs ]; then mkdir logs; fi
	docker compose exec app bash workflows/execute_workflows.sh > logs/run_$$(date +"%s").log

stop:
	CONTAINER_ID=$$(docker ps | grep quiver | cut -d' ' -f1); docker container stop $$CONTAINER_ID && docker container remove $$CONTAINER_ID