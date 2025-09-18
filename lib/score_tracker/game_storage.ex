defmodule ScoreTracker.GameStorage do
  alias ScoreTracker.GameManager

  @doc """
  Initialize the game storage backend
  """
  @callback init(prefix :: atom(), opts: keyword()) :: atom()

  @doc """
  Save the current state of a game to the storage backend
  """
  @callback save_state(prefix :: atom(), game_id :: String.t(), game_state :: GameManager.game()) ::
              :ok | :error

  @doc """
  Get a game's state from the storage backend
  """
  @callback get_game(prefix :: atom(), game_id :: String.t()) ::
              {:ok, GameManager.game()} | {:error, :not_found}
end
