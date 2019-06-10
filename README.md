# Live Qchatex
## Open sourced web application done by [Fiqus](https://fiqus.coop) for educational purposes.

The idea was to research and practice about [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view) implementation and to play around a little with [Phoenix PubSub](https://hexdocs.pm/phoenix_pubsub/) sockets using [Mnesia](http://erlang.org/doc/apps/mnesia/) over [Memento](https://github.com/sheharyarn/memento) for storage.

[Live Qchatex](https://github.com/fiqus/lqchatex) is a very simple and quick chat engine that allows you to create and join chat rooms on-the-fly.  
Don't need to register, just enter a nickname and you are ready to go!

## Live running demo at: [https://lqchatex.fiqus.coop/](https://lqchatex.fiqus.coop/)  
Powered by [gigalixir](https://gigalixir.com/).


# Development
## Pre-requisites:
You will have to install:
  * `Elixir` 1.8 or later
  * `Erlang/OTP` 20 or later
  * `Node.js` 5 or later

## Start the server

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

You can now visit [http://localhost:4000](http://localhost:4000) from your browser!

## Test
  * `mix test` - run the tests
  * `mix coverage` - for test coverage

## Mnesia
  * `mix mnesia.reset` - remove the mnesia storage directory from disk