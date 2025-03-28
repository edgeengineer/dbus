#!/bin/bash
set -e

echo "Building Docker image for testing..."
docker-compose build

echo "Running tests in Docker container..."
docker-compose run test

echo "Tests completed."
