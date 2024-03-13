.PHONY: build clean clean-results clean-workspaces prepare-default-gt run start stop

build:
	docker compose build

start:
	docker compose up -d
	docker compose run -d ocr

prepare-default-gt:
	docker compose exec ocr bash scripts/prepare.sh
	python3 helpers/post_gt_to_mongodb.py

custom-gt:
# TODO: GT --> OCR-D workspaces
	python3 helpers/post_gt_to_mongodb.py

post-workflows:
	python3 helpers/post_workflows_to_mongodb.py

post-gt:
	python3 helpers/post_gt_to_mongodb.py

run:
	mkdir -p logs
	docker compose exec ocr bash scripts/run_trigger.sh

reinstall:
	docker compose exec ocr pip install -e .

restart:
	make stop
	make build
	make start

stop:
	CONTAINER_ID=$$(docker ps | grep quiver | cut -d' ' -f1); docker container stop $$CONTAINER_ID && docker container rm $$CONTAINER_ID

clean-workspaces:
	docker compose exec ocr rm -rf workflows/workspaces

clean-results:
	docker compose exec ocr rm -rf workflows/nf-results workflows/results

clean: clean-workspaces clean-results
	@echo "Cleaning everything."
