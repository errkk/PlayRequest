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
