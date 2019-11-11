.PHONY: server server1 server2 release compile clean

export MIX_ENV ?= dev
export SECRET_KEY_BASE ?= $(shell mix phx.gen.secret)

server:
	@iex --name lqchatex@127.0.0.1 -S mix phx.server

server1:
	@PORT=4001 iex --name s1@127.0.0.1 -S mix phx.server
server2:
	@PORT=4002 iex --name s2@127.0.0.1 -S mix phx.server

release:
	@MIX_ENV=prod mix release && _build/prod/rel/lqchatex/bin/lqchatex start --name rel@127.0.0.1

compile:
	@mix compile

clean:
	@mix mnesia.reset && mix deps.clean --all && rm -rf deps _build && mix deps.get