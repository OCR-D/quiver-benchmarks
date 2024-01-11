.PHONY: build clean clean-results clean-workspaces prepare-default-gt run start stop

build:
	docker compose build

start:
	docker compose run -d app

prepare-default-gt:
	docker compose exec app bash scripts/prepare.sh

run:
	mkdir -p logs
	docker compose exec app bash workflows/execute_workflows.sh > logs/run_$$(date +"%s").log

stop:
	docker container stop quiver-benchmarks_app && docker container rm quiver-benchmarks_app

clean-workspaces:
	docker compose exec app rm -rf workflows/workspaces

clean-results:
	docker compose exec app rm -rf workflows/nf-results workflows/results

clean: clean-workspaces clean-results
	@echo "Cleaning everything."
