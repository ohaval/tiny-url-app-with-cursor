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
	# Sets up required AWS infrastructure for CDK deployments (S3 bucket, IAM roles).
	# Run once per AWS account/region before first deployment or after major CDK upgrades.
	cdk bootstrap

deploy:
	cdk deploy

destroy:
	cdk destroy
