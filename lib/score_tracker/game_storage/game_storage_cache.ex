defmodule ScoreTracker.GameStorage.Cache do
  @behaviour ScoreTracker.GameStorage

  alias ScoreTracker.Cache

  @week_in_seconds 604_800

  @impl ScoreTracker.GameStorage
  def init(prefix, _opts), do: prefix

  @impl ScoreTracker.GameStorage
  def save_state(prefix, game_id, game_state) do
    with {:ok, state} <- Jason.encode(game_state),
         {:ok, _} <- Cache.command(["SET", key(prefix, game_id), state, "EX", @week_in_seconds]) do
      :ok
    else
      _ -> :error
    end
  end

  @impl ScoreTracker.GameStorage
  def get_game(prefix, game_id) do
    with {:ok, state} when not is_nil(state) <- Cache.command(["GET", key(prefix, game_id)]),
         {:ok, game_state} <- Jason.decode(state) do
      game_state =
        Enum.reduce(game_state, %{}, fn
          {key, value}, acc when key in ["status", "game_mode"] ->
            Map.put(acc, String.to_existing_atom(key), String.to_existing_atom(value))

          {key, value}, acc ->
            Map.put(acc, String.to_existing_atom(key), value)
        end)

      {:ok, game_state}
    else
      _ ->
        {:error, :not_found}
    end
  end

  defp key(prefix, game_id), do: "#{prefix}_#{game_id}"
end
