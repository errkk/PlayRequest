define PG
brew services start postgresql@14 &&
endef

define ENV
source .env && 
endef

define MIGRATE
mix ecto.migrate && 
endef

define DEPS
mix deps.get && 
endef

setup:
	# For postgres > 14, the default user isn't created so make one here
	$(PG) $(ENV) $(DEPS) \
	echo "You'll need to enter a pasword in a min" && \
	echo "It's just for development, so you you use 1234 you wont have to edit config/{dev|test}.exs" && \
	createuser -P -s -e pr_user && echo "User created" || echo "User not created, never mind, maybe you already did?" && \
	mix ecto.setup
.PHONY: dev

dev:
	$(PG) $(ENV) $(DEPS) $(MIGRATE)\
	mix phx.server
.PHONY: dev

iex:
	$(PG) $(ENV) $(DEPS) $(MIGRATE)\
	iex --erl "-kernel shell_history enabled" -S mix
.PHONY: iex

rollback:
	$(PG) $(ENV) $(DEPS) \
	mix ecto.rollback
.PHONY: rollback

test_watch:
	$(PG) $(ENV) $(DEPS)\
	mix test.watch
.PHONY: test_watch

test:
	$(PG) $(DEPS)\
	mix test
.PHONY: test

stop:
	brew services stop postgresql
.PHONY: stop

format_code:
	mix format mix.exs "lib/**/*.{ex,exs}" "test/**/*.{ex,exs}"
.PHONY: format_code

proxy_production:
	fly proxy 5433:5432 --app sonosnow-db
.PHONY: proxy_production

proxy_staging:
	fly proxy 5433:5432 --app sonosnow-staging-db
.PHONY: proxy_staging

console_staging:
	fly ssh console --app sonosnow-staging
.PHONY: console_staging

console_production:
	fly ssh console --app sonosnow
.PHONY: console_production

remote_staging:
	fly ssh console -C "/home/elixir/app/bin/pr remote"  --app sonosnow-staging
.PHONY: console_staging

remote_production:
	fly ssh console -C "/home/elixir/app/bin/pr remote"  --app sonosnow
.PHONY: console_production

tunnel:
	$(ENV)\
	ssh -p 443 -R0:localhost:4000 ${PINGY_TOKEN}@a.pinggy.online
.PHONY: tunnel
