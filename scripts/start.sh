#!/bin/sh
echo "Viewing migrations"
bin/pr eval "PR.Release.migration_status";
echo "Running migrations"
bin/pr eval "PR.Release.migrate";

ip=$(grep fly-local-6pn /etc/hosts | cut -f 1)
export RELEASE_DISTRIBUTION=name
export RELEASE_NODE=$FLY_APP_NAME@$ip

echo "Starting server ${RELEASE_NODE}"
bin/pr start;


