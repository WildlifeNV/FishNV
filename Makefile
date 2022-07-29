.PHONY: clone clean up down exec-api exec-db

up:
	docker-compose up --build

down:
	docker-compose down

clone:
	git clone https://github.com/WildlifeNV/fishnv-database.git
	git clone -b next https://github.com/WildlifeNV/fishnv-api.git
	git clone -b next https://github.com/WildlifeNV/fishnv-app.git

clean:
	rm -rf fishnv-api fishnv-app fishnv-database

exec-api:
	docker compose exec -it api /bin/sh

exec-db:
	docker compose exec -it -u postgres db /bin/sh