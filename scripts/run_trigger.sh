#!/usr/bash

# the $RELEASE_TAG variable is handed over by the webhook to this
# application
mkdir -p logs
echo "Clean up everything."
rm -rf workflows/workspaces workflows/nf-results workflows/results
quiver run-ocr > logs/run_$(date +"%F-%H:%M:%S").log
