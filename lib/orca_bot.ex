defmodule OrcaBot do
  use Kaguya.Module, "main"
  import OrcaBot.Util

  unless File.exists?("_db"), do: File.mkdir("_db")

  # Validator for mods
  def is_mod(%{user: %{nick: nick}, args: [chan]}) do
    pid = Kaguya.Util.getChanPid(chan)
    user = GenServer.call(pid, {:get_user, nick})

    if user == nil do
      false
    else
      user.mode == :op
    end
  end

  # Validator for rate limiting
  def rate_limit(msg) do
    {rate, _} = ExRated.check_rate(msg.trailing, 10_000, 1)

    case rate do
      :ok    -> true
      :error -> false
    end
  end

  # Enable Twitch Messaging Interface and whispers
  handle "001" do
    GenServer.call(Kaguya.Core, {:send, %Kaguya.Core.Message{command: "CAP", args: ["REQ"], trailing: "twitch.tv/membership"}})
    GenServer.call(Kaguya.Core, {:send, %Kaguya.Core.Message{command: "CAP", args: ["REQ"], trailing: "twitch.tv/commands"}})

    Kaguya.Util.sendPM("Hiya!", "#orcastraw")
  end

  # Commands list
  handle "PRIVMSG" do
    enforce :rate_limit do
      match "!uptime", :uptime
      match "!time", :local_time
      match ["!coin", "!flip"], :coin_flip
      match "!predict ~question", :prediction
      match "!quote", :get_quote
      match_all :custom_command
    end

    match "!join", :join_queue
    match "!leave", :leave_queue

    match ["hello", "hi", "hey", "sup"], :hello
    match ["same", "Same", "SAME"], :same
    match ["PogChamp", "Kappa", "FrankerZ", "Kreygasm", "BibleThump"], :emote

    # Mod command list
    enforce :is_mod do
      match "!ping", :ping
      match "!next", :next_in_queue
      match "!set :command ~action", :set_custom_command
      match "!del :command", :delete_custom_command
      match "!addquote ~quote_text", :add_quote
      match "!delquote :quote_id", :del_quote
    end
  end

  # Command action handlers
  defh uptime do
    url = "https://decapi.me/twitch/uptime?channel=orcastraw"
    request =  HTTPoison.get! url

    case request.body do
      "Channel is not live." -> reply "Stream is not online!"
      time -> reply "Stream has been live for #{time}."
    end
  end

  defh local_time do
    {{_, _, _}, {hour, minute, _}} = :calendar.local_time

    h = cond do
      hour <= 9 -> "0#{hour}"
      true      -> "#{hour}"
    end

    m = cond do
      minute <= 9 -> "0#{minute}"
      true        -> "#{minute}"
    end

    reply "It is #{h}:#{m} CST Orcastraw's time."
  end

  defh coin_flip, do: reply Enum.random(["Heads.", "Tails."])

  defh prediction(%{"question" => q}) do
    predictions = [
      "It is certain.",
      "It is decidedly so.",
      "Without a doubt.",
      "Yes, definitely.",
      "You may rely on it.",
      "As I see it, yes.",
      "Most likely.",
      "Outlook good.",
      "Yes.",
      "Signs point to yes.",
      "Reply hazy, try again.",
      "Ask again later.",
      "Better not tell you now.",
      "Cannot predict now.",
      "Concentrate and ask again.",
      "Don't count on it.",
      "My reply is no.",
      "My sources say no.",
      "Outlook not so good.",
      "Very doubtful."
    ]

    reply Enum.random(predictions)
  end

  defh get_quote do
    quotes = query_all_data(:quotes)
    {quote_id, quote_text} = Enum.random(quotes)

    reply "[\##{quote_id}] #{quote_text}"
  end

  defh custom_command do
    action = query_data(:commands, message.trailing)

    case action do
      nil -> nil
      action -> reply action
    end
  end

  defh hello do
    replies = ["sup loser", "yo", "ay", "hi", "wassup"]
    if one_to(25) do
      reply Enum.random(replies)
    end
  end

  defh same do
    if one_to(25) do
      reply "same"
    end
  end

  defh emote do
    if one_to(25) do
      reply message.trailing
    end
  end

  defh join_queue(%{user: %{nick: nick}}) do
    current_queue = query_data(:queue, "queue")
    queue = case current_queue do
      nil -> []
      queue -> queue
    end

    case Enum.member?(queue, nick) do
      false ->
        queue = queue ++ [nick]
        store_data(:queue, "queue", queue)
        update_queue(queue)

        reply "@#{nick}, you're now added to the queue."
      true -> nil
    end
  end

  defh leave_queue(%{user: %{nick: nick}}) do
    current_queue = query_data(:queue, "queue")
    queue = case current_queue do
      nil -> []
      queue -> queue
    end

    case Enum.member?(queue, nick) do
      true ->
        queue = queue -- [nick]
        store_data(:queue, "queue", queue)
        update_queue(queue)

        reply "@#{nick}, you've been removed from the queue."
      false -> nil
    end
  end

  # Moderator action handlers
  defh ping, do: reply "Pong!"

  defh next_in_queue do
    current_queue = query_data(:queue, "queue")

    case current_queue do
      nil -> reply "There is no one in queue."
      queue ->
        first = List.first(queue)
        queue = queue -- [first]
        store_data(:queue, "queue", queue)
        update_queue(queue)

        next = List.first(queue)

        case next do
          nil -> reply "@#{first} is now playing."
          next -> reply "@#{first} is now playing. @#{next} is next!"
        end
    end
  end

  defh set_custom_command(%{"command" => command, "action" => action}) do
    exists = query_data(:commands, "!#{command}")
    store_data(:commands, "!#{command}", action)

    case exists do
      nil -> reply "Alright! Type !#{command} to use."
      _   -> reply "Done, command !#{command} updated."
    end
  end

  defh delete_custom_command(%{"command" => command}) do
    action = query_data(:commands, "!#{command}")

    case action do
      nil -> reply "Command does not exist."
      _   ->
        delete_data(:commands, "!#{command}")
        reply "Command !#{command} removed."
    end
  end

  defh add_quote(%{"quote_text" => quote_text}) do
    quotes = query_all_data(:quotes)
    IO.inspect(quotes)
    quote_id = case quotes do
      nil -> 1
      _ ->
        {quote_id, _} = List.last(quotes)
        quote_id
    end

    store_data(:quotes, quote_id, quote_text)
    reply "Quote added! #{quote_id} quotes total."
  end

  defh del_quote(%{"quote_id" => quote_id}) do
    case quote_id |> Integer.parse do
      {quote_id, _} ->
        case query_data(:quotes, quote_id) do
          nil -> reply "Quote \##{quote_id} does not exist."
          _ ->
            delete_data(:quotes, quote_id)
            reply "Quote removed."
        end
      :error -> reply "You didn't specify an ID number."
    end
  end
end
