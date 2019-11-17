.PHONY: server server1 server2 release compile test clean

export MIX_ENV ?= dev
export SECRET_KEY_BASE ?= $(shell mix phx.gen.secret)
export RELEASE_COOKIE=iiqNpbss-O-SQBkwCYr6EVp8PSx6aDzfGU1rSCmjTMSSeQoiupl4DnFiqus!==

server:
	@iex --name server@127.0.0.1 --cookie "$(RELEASE_COOKIE)" -S mix phx.server

server1:
	@PORT=4001 iex --name s1@127.0.0.1 --cookie "$(RELEASE_COOKIE)" -S mix phx.server
server2:
	@PORT=4002 iex --name s2@127.0.0.1 --cookie "$(RELEASE_COOKIE)" -S mix phx.server

release: MIX_ENV=prod
release:
	@cd assets && NODE_ENV=prod npm run deploy
	@mix phx.digest && PORT=4004 mix release
	@_build/prod/rel/lqchatex/bin/lqchatex start_iex

compile:
	@mix compile

test: MIX_ENV=test
test:
	@mix test

clean:
	@mix mnesia.reset && mix deps.clean --all --unlock
	@rm -rf deps _build priv/static/*
	@mix deps.get