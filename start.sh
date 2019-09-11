#!/bin/sh

cd /app/apps/pr_web;
mix phx.digest -o ~/_build/prod/rel/pr/lib/pr_web-0.1.0/priv/static;
cd ~;
_build/prod/rel/pr/bin/pr start;

