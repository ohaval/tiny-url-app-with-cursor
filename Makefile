.PHONY: lint test install

lint:
	pre-commit run --all-files

test:
	pytest

install:
	pip install -r requirements.txt
