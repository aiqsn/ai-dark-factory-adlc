# Every workflow calls these targets, so the factory doesn't care which language the app uses.
BASE ?= origin/main

.PHONY: install test mutation dev serve image probe deploy-first package

install:            ## install dependencies exactly as locked
	npm ci

test:               ## unit tests; must exit non-zero on any failure
	npm test

mutation:           ## mutate only files changed since $(BASE); fails if too many mutants survive
	@files=$$(git diff --name-only --diff-filter=AM $(BASE)...HEAD -- 'src/*.js' 'src/**/*.js' | paste -sd, -); \
	if [ -z "$$files" ]; then echo "No changed source files to mutate."; exit 0; fi; \
	echo "Mutating: $$files"; \
	npx stryker run --mutate "$$files"

dev:                ## run the app locally on http://127.0.0.1:8787
	npx wrangler dev --ip 127.0.0.1 --port 8787

serve:              ## run the container entry point (src/server.js) on http://127.0.0.1:8080
	GIT_SHA=$${SHA:-dev} node src/server.js

image:              ## build the container image used by deploy-gcp.yml and deploy-azure.yml
	docker build -t $${IMAGE:-dark-factory-starter:dev} .

probe:              ## run the production probes against URL (default: local dev server)
	bash .github/factory/smoke.sh "$${URL:-http://127.0.0.1:8787}"

deploy-first:       ## one-time manual deploy, so the deploy workflow has a stable version to fall back to
	npx wrangler deploy

package:            ## AWS only: dist/function.zip for Lambda (handler src/lambda.handler); SHA is served by /version
	rm -rf dist && mkdir -p dist
	echo "$${SHA:-dev}" > VERSION
	zip -qr dist/function.zip src package.json VERSION
	rm -f VERSION
