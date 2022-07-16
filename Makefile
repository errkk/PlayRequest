define PG
brew services start postgresql &&
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
