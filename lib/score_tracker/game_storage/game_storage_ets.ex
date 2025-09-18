defmodule ScoreTracker.GameStorage.Ets do
  @behaviour ScoreTracker.GameStorage

  @impl ScoreTracker.GameStorage
  def init(table_name, opts), do: :ets.new(table_name, opts)

  @impl ScoreTracker.GameStorage
  def save_state(table, game_id, game_state) do
    :ets.insert(table, {game_id, game_state})
    :ok
  end

  @impl ScoreTracker.GameStorage
  def get_game(table, game_id) do
    case :ets.lookup(table, game_id) do
      [{^game_id, game_state}] -> {:ok, game_state}
      _ -> {:error, :not_found}
    end
  end
end
