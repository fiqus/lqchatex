# Live Qchatex
## Open sourced web application done by [Fiqus](https://fiqus.coop) for educational and experimental purposes.

The idea was to research and practice about [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view) implementation and to play around a little with [Phoenix PubSub](https://hexdocs.pm/phoenix_pubsub/) + [Presence](https://hexdocs.pm/phoenix/Phoenix.Presence.html) for sockets, using [Memento](https://github.com/sheharyarn/memento) as [Elixir](https://elixir-lang.org/) wrapper to [Erlang Mnesia](https://learnyousomeerlang.com/mnesia) for data storage.  
Added clustering support by using [libcluster](https://github.com/bitwalker/libcluster), allowing Phoenix and Mnesia to work as distributed servers.

[Live Qchatex](https://github.com/fiqus/lqchatex) is a very simple and quick chat engine that allows you to create and join chat rooms on-the-fly.  
Don't need to register, just enter a nickname and you are ready to go!  
**NOTE:** All chats, messages and users are automatically deleted after a certain period of inactivity.

### App overview PDF: [lqchatex-overview.pdf](https://lqchatex.fiqus.coop/lqchatex-overview.pdf) 

## Live running demo at: [https://lqchatex.fiqus.coop/](https://lqchatex.fiqus.coop/)  
Hosted by [gigalixir](https://gigalixir.com/).


# Development
## Pre-requisites
You will have to install:
  * `Elixir` 1.9 or later
  * `Erlang/OTP` 22 or later
  * `Node.js` 12 or later

## Start a single server

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

You can now visit [http://localhost:4000](http://localhost:4000) from your browser!

## Mnesia reset data
  * `mix mnesia.reset` - remove the mnesia storage directory from disk

## Makefile
  * `make clean` - remove mnesia data, _build/, priv/static/ and clean+unlock deps
  * `make test` - run tests
  * `make server` - run default server instance at *server@127.0.0.1* node accessible from [http://localhost:4000](http://localhost:4000)
  * `make server1` - run additional server instance at *s1@127.0.0.1* node accessible from [http://localhost:4001](http://localhost:4001)
  * `make server2` - run additional server instance at *s2@127.0.0.1* node accessible from [http://localhost:4002](http://localhost:4002)
  * `make release` - build prod release and run it at *lqchatex@127.0.0.1* node accessible from [http://localhost:4004](http://localhost:4004)

Multiple server instances will connect to each other using **libcluster** with *gossip* topology!  
You can try the cluster by running `server`, `server1`, `server2` and `release` at the same time.