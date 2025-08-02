defmodule Ripple.Game do
  alias Ripple.GameManager

  @doc """
  The PubSub topic for a game
  """
  @spec topic(String.t()) :: String.t()
  def topic(game_id), do: "game:##{game_id}"

  @doc """
  """
  @spec get(String.t()) :: {:ok, GameManager.game()} | {:error, :not_found}
  def get(game_id), do: GameManager.get_game(game_id)

  @doc """
  Calculate a player's total score
  """
  @spec player_total_score(String.t(), GameManager.game()) :: non_neg_integer()
  def player_total_score(player_id, game) do
    game.scores[player_id]
    |> Map.values()
    |> Enum.sum()
  end
end
