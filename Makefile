ifeq ($(shell type podman-compose >/dev/null 2>&1 && echo y),)
# Use docker / docker compose
DOCKER_COMPOSE=docker compose
DOCKER=docker
else
# Use podman / podman-compose
DOCKER_COMPOSE=podman-compose
DOCKER=podman
endif

.PHONY: build clean clean-results clean-workspaces prepare-default-gt run start stop

build:
	$(DOCKER_COMPOSE) build

start:
	$(DOCKER_COMPOSE) run -d --name quiver-benchmarks_app app

prepare-default-gt:
	$(DOCKER_COMPOSE) exec app bash scripts/prepare.sh

run:
	mkdir -p logs
	$(DOCKER_COMPOSE) exec app bash workflows/execute_workflows.sh > logs/run_$$(date +"%s").log 2>&1

stop:
	$(DOCKER) container stop quiver-benchmarks_app && $(DOCKER) container rm quiver-benchmarks_app

clean-workspaces:
	$(DOCKER_COMPOSE) exec app rm -rf workflows/workspaces

clean-results:
	$(DOCKER_COMPOSE) exec app rm -rf workflows/nf-results workflows/results

clean: clean-workspaces clean-results
	@echo "Cleaning everything."
