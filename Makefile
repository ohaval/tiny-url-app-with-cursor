.PHONY: lint test install

lint:
	pre-commit run --all-files

local-test lt:
	python -m pytest tests

install:
	pip install -r requirements.txt
