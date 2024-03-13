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
	$(DOCKER_COMPOSE) up -d
	$(DOCKER_COMPOSE) run -d ocr

prepare-default-gt:
	$(DOCKER_COMPOSE) exec ocr bash scripts/prepare.sh
	python3 helpers/post_gt_to_mongodb.py

run:
	mkdir -p logs
	$(DOCKER_COMPOSE) exec ocr bash scripts/run_trigger.sh

reinstall:
	$(DOCKER_COMPOSE) exec ocr pip install -e .

restart:
	make stop
	make build
	make start

stop:
	CONTAINER_ID=$$($(DOCKER) ps | grep quiver | cut -d' ' -f1); $(DOCKER) container stop $$CONTAINER_ID && $(DOCKER) container rm $$CONTAINER_ID

clean-workspaces:
	rm -rf workflows/workspaces

clean-results:
	rm -rf workflows/nf-results workflows/results

clean: clean-workspaces clean-results
	@echo "Cleaned everything."
