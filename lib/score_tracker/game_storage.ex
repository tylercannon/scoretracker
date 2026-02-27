defmodule ScoreTracker.GameStorage do
  @moduledoc """
  Behaviour for saving and retrieving
  game state from a storage backend.
  """

  alias ScoreTracker.Game

  @doc """
  Save the current state of a game to the storage backend.
  """
  @callback save_state(game_id :: String.t(), game_state :: Game.t()) :: :ok | :error

  @doc """
  Get a game's state from the storage backend.
  """
  @callback get_game(game_id :: String.t()) :: {:ok, Game.t()} | {:error, :not_found}
end
