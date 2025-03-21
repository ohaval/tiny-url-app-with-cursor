.PHONY: lint local-test lt

lint:
	pre-commit run --all-files

local-test lt:
	pytest

install:
	pip install -r requirements.txt
