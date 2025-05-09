.PHONY: lint lt e2e install cdk-synth cdk-bootstrap deploy destroy e2e-test

lint:
	pre-commit run --all-files

install:
	pip install -r requirements.txt

local-test lt:
	python -m pytest tests

e2e:
	@if [ -z "$(API_ENDPOINT)" ]; then \
		echo "Error: API_ENDPOINT environment variable must be set"; \
		echo "Usage: API_ENDPOINT=https://your-api-url.execute-api.region.amazonaws.com/prod make e2e"; \
		exit 1; \
	else \
		echo "Using API endpoint: $(API_ENDPOINT)"; \
	fi; \
	API_ENDPOINT=$(API_ENDPOINT) python -m pytest tests/e2e/test_shorten_url.py -v

cdk-synth:
	# Synthesizes CloudFormation templates from your CDK code.
	# Use to preview what will be deployed and validate infrastructure code before deployment.
	cdk synth

cdk-bootstrap:
	# Sets up required AWS infrastructure for CDK deployments (S3 bucket, IAM roles).
	# Run once per AWS account/region before first deployment or after major CDK upgrades.
	cdk bootstrap

deploy:
	cdk deploy --require-approval never

destroy:
	cdk destroy
