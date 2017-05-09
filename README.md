# OrcaBot

## Setup

Install [Elixir](http://elixir-lang.org/)

Then, clone the directory.

```
$ git clone https://github.com/rekyuu/OrcaBot
```

Modify the `config/config.exs` for the bot's username, and create `config/secret.exs` for the oauth code. `secret.exs` should read as follows:

```elixir
use Mix.Config

config :kaguya,
  password: "oauth:blahblahblahblahblahblahblaaah"
```

Then run the bot:

```
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
