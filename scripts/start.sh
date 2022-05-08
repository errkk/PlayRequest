#!/bin/sh

echo "Migrating"
./migrate.sh

echo "Starting"
bin/pr start

