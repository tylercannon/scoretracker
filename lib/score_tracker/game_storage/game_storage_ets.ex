defmodule ScoreTracker.GameStorage.Ets do
  @moduledoc """
  Game storage backend for storing game
  state to ETS.
  """

  @behaviour ScoreTracker.GameStorage

  @table_name :lobbies

  @impl ScoreTracker.GameStorage
  def save_state(game_id, game_state) do
    :ets.insert(@table_name, {game_id, game_state})
    :ok
  end

  @impl ScoreTracker.GameStorage
  def get_game(game_id) do
    case :ets.lookup(@table_name, game_id) do
      [{^game_id, game_state}] -> {:ok, game_state}
      _ -> {:error, :not_found}
    end
  end
end
