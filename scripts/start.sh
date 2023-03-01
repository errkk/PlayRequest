#!/bin/sh
echo "Viewing migrations"
bin/pr eval "PR.Release.migration_status";
echo "Running migrations"
bin/pr eval "PR.Release.migrate";

ip=$(grep fly-local-6pn /etc/hosts | cut -f 1)
export RELEASE_DISTRIBUTION=name
# This has to be the same between all nodes that cluster
export RELEASE_COOKIE=$FLY_APP_NAME
export RELEASE_NODE=$FLY_APP_NAME@$ip

echo "Starting server ${RELEASE_NODE}"
RELEASE_NODE=$RELEASE_NODE RELEASE_COOKIE=$RELEASE_COOKIE RELEASE_DISTRIBUTION=$RELEASE_DISTRIBUTION /pr start;


