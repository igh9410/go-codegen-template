.PHONY: all run generate-docs generate-server generate-client 

all: generate-docs generate-server generate-client

generate-docs:
	@echo 'Generating Swagger docs...'
	@protoc proto/*.proto -I=proto/ -I=proto/third_party --openapi_out=docs --openapi_opt=enum_type=string

generate-server:
	@oapi-codegen --generate=echo-server,strict-server,embedded-spec --package=api -o internal/api/server.gen.go docs/openapi.yaml
	@oapi-codegen --generate=models --package=api -o internal/api/types.gen.go docs/openapi.yaml
	@go fmt ./internal/api

generate-client:
	@protoc proto/*.proto -I=proto/ -I=proto/third_party --openapi_out=dist --openapi_opt=default_response=false --openapi_opt=enum_type=string
	@npx openapi-typescript-codegen -i dist/openapi.yaml -o ../frontend/src/api --name ApiClient --client fetch
	@rm dist/openapi.yaml


# Run golangci-lint
linter:
	golangci-lint run

# Create database migration file
create-migration:
	@cd ./db/migrations && goose create $(filter-out $@,$(MAKECMDGOALS)) sql
	@echo "Migration created."

goose-version:
	@goose -dir db/migrations postgres "host=localhost user=postgres password=password dbname=postgres sslmode=disable port=5432" version

# Run the database migrations
migrate-up:
	@echo "Running the database migrations..."
	@goose -dir db/migrations postgres "host=localhost user=postgres password=password dbname=postgres sslmode=disable port=5432" up

# Rollback the database migrations
migrate-down:
	@echo "Rolling back the database migrations..."
	@goose -dir db/migrations postgres "host=localhost user=postgres password=password dbname=postgres sslmode=disable port=5432" down

# Run the tests
test:
	@echo "Running the tests..."
	@go test ./... -v -cover -coverprofile=coverage.out
