.PHONY: lint test install cdk-synth cdk-deploy cdk-bootstrap cdk-destroy

lint:
	pre-commit run --all-files

local-test lt:
	python -m pytest tests

install:
	pip install -r requirements.txt

cdk-synth:
	cdk synth

cdk-bootstrap:
	cdk bootstrap

cdk-deploy:
	cdk deploy

cdk-destroy:
	cdk destroy
