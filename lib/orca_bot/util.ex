defmodule OrcaBot.Util do
  def app_dir, do: "#{Application.app_dir(:twitch_kuma)}"

  def whisper(user, msg), do: Kaguya.Util.sendPM("/w #{user} #{msg}", "#jtv")

  def one_to(n), do: Enum.random(1..n) <= 1
  def percent(n), do: Enum.random(1..100) <= n

  def update_queue(queue) do
    list_of_players = for player <- queue do
      place = Enum.find_index(queue, fn(x) -> x == player end)
      "#{place + 1}. #{player}\n"
    end

    File.write("_db/queue.txt", list_of_players |> Enum.join)
  end

  def store_data(table, key, value) do
    file = '_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])

    :dets.insert(table, {key, value})
    :dets.close(table)
  end

  def query_data(table, key) do
    file = '_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])
    result = :dets.lookup(table, key)

    response =
      case result do
        [{_, value}] -> value
        [] -> nil
      end

    :dets.close(table)
    response
  end

  def query_all_data(table) do
    file = '_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])
    result = :dets.match_object(table, {:"$1", :"$2"})

    response =
      case result do
        [] -> nil
        values -> values
      end

    :dets.close(table)
    response
  end

  def delete_data(table, key) do
    file = '_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])
    response = :dets.delete(table, key)

    :dets.close(table)
    response
  end
end
