#!/bin/sh
echo "Running migrations"
bin/pr eval "PR.ReleaseTasks.migrate";

echo "Starting server"
bin/pr start;


