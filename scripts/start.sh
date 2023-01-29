#!/bin/sh
echo "Viewing migrations"
bin/pr eval "PR.Release.migration_status";
echo "Running migrations"
bin/pr eval "PR.Release.migrate";

echo "Starting server"
bin/pr start;


