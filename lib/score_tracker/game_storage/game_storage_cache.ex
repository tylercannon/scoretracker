defmodule ScoreTracker.GameStorage.Cache do
  @moduledoc """
  Game storage backend for storing game
  state to an external cache service.
  """

  @behaviour ScoreTracker.GameStorage

  alias ScoreTracker.{Cache, Game}

  @prefix "lobbies"
  @week_in_seconds 604_800

  @impl ScoreTracker.GameStorage
  def save_state(game_id, game_state) do
    with {:ok, state} <- Jason.encode(game_state),
         {:ok, _} <- Cache.command(["SET", key(game_id), state, "EX", @week_in_seconds]) do
      :ok
    else
      _ -> :error
    end
  end

  @impl ScoreTracker.GameStorage
  def get_game(game_id) do
    with {:ok, state} when not is_nil(state) <- Cache.command(["GET", key(game_id)]),
         {:ok, game_state} <- Game.from_json(state) do
      {:ok, game_state}
    else
      _ ->
        {:error, :not_found}
    end
  end

  defp key(game_id), do: "#{@prefix}_#{game_id}"
end
