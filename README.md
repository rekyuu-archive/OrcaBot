# OrcaBot

## Setup

Install [Elixir](http://elixir-lang.org/)

Modify the `config/secret.exs` for the oauth code. Should read as follows:

```elixir
use Mix.Config

config :kaguya,
  password: "oauth:blahblahblahblahblahblahblaaah"
```

```
$ git clone https://github.com/rekyuu/OrcaBot
$ cd OrcaBot
$ mix deps.get
$ iex -S mix
```

## Available commands

- `!coin` or `!flip` - flips a coin
- `!predict (question)` - 8ball prediction
- `!time` - Orca's local time
- `!uptime` - stream uptime
- `!join` - joins the queue
- `!leave` - leaves the queue

## Moderator commands

- `!ping` - ping/pong
- `!next` - next person in queue
- `!set :command ~action` - sets a custom command and response
- `!del :command` - removes a custom command
- `!addquote ~quote` - adds a quote
- `!delquote :quote_id` - removes a quote
