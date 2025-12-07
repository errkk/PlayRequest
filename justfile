# vim: set ft=make :
# If Just isn't installed, install it with homebrew
# brew install just

set dotenv-load

appname := 'sonosnow'
binname := 'pr'

deps:
	mix deps.get

migrate:
	mix ecto.migrate

start_pg:
	brew services start postgresql@14

stop:
	brew services stop postgresql

setup: deps start_pg migrate
	echo "You'll need to enter a pasword in a min" && \
	echo "It's just for development, so you you use 1234 you wont have to edit config/{dev|test}.exs" && \
	createuser -P -s -e {{binname}}_user && echo "User created" || echo "User not created, never mind, maybe you already did?" && \
	mix ecto.setup

dev: deps start_pg migrate
	mix phx.server

iex:
	iex --erl "-kernel shell_history enabled" -S mix

rollback:
	mix ecto.rollback

test_watch: deps start_pg migrate
	mix test.watch

test: deps start_pg migrate
	mix test

format_code:
	mix format mix.exs "lib/**/*.{ex,exs}" "test/**/*.{ex,exs}"

proxy_production:
	fly proxy 5433:5432 --app {{appname}}-db

proxy_staging:
	fly proxy 5433:5432 --app {{appname}}-staging-db

console_staging:
	fly ssh console --app {{appname}}-staging

console_production:
	fly ssh console --app {{appname}}

remote_staging:
	fly ssh console -C "/home/elixir/app/bin/{{binname}} remote"  --app {{appname}}-staging

remote_production:
	fly ssh console -C "/home/elixir/app/bin/{{binname}} remote"  --app {{appname}}

tunnel:
	cloudflared tunnel run --token ${CLOUDFLARE_TOKEN}
