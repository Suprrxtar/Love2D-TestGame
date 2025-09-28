#!/bin/bash

echo "Running Earth Survival Game Tests..."
echo

# Check if Love2D is installed
if ! command -v love &> /dev/null; then
    echo "Error: Love2D is not installed or not in PATH"
    echo "Please install Love2D from https://love2d.org/"
    exit 1
fi

# Run the tests
echo "Starting test execution..."
love test_project

echo
echo "Tests completed!"
