defmodule ScoreTracker.Game do
  @moduledoc """
  Helper functions related to displaying
  game state in the UI
  """

  alias ScoreTracker.{GameManager, GameType}

  @doc """
  The PubSub topic for a game
  """
  @spec topic(String.t()) :: String.t()
  def topic(game_id), do: "game:##{game_id}"

  @doc """
  Get a game by it's id
  """
  @spec get(String.t()) :: {:ok, GameManager.game()} | {:error, :not_found}
  def get(game_id), do: GameManager.get_game(game_id)

  @doc """
  Check whether a game is in progress
  """
  @spec in_progress?(GameManager.game()) :: boolean()
  def in_progress?(game), do: game.status == :in_progress

  @doc """
  Check whether a user is the host of a game
  """
  @spec host?(GameManager.game(), String.t()) :: boolean()
  def host?(game, user_id), do: game.host_id == user_id

  @doc """
  Check whether a user's score is editable
  """
  @spec user_score_editable?(GameManager.game(), String.t(), String.t()) :: boolean()
  def user_score_editable?(game, player_id, user_id) do
    cond do
      not in_progress?(game) -> false
      host?(game, user_id) -> true
      game.game_mode == :party and player_id == user_id -> true
      true -> false
    end
  end

  @doc """
  Get the friend game type header
  """
  @spec get_game_type_header(GameType.game_type()) :: String.t()
  def get_game_type_header(game_type) do
    case game_type do
      :rummy -> "Rummy"
      :ripple -> "Ripple"
      :custom -> "Custom Game"
    end
  end

  @doc """
  Get the friendly status of a game
  """
  @spec get_status(GameManager.status()) :: String.t()
  def get_status(status) do
    case status do
      :in_progress -> "In Progress"
      :waiting_for_players -> "Waiting for Players"
      :complete -> "Complete"
    end
  end

  @doc """
  Get the friendly error message for a given join game error code
  """
  @spec get_join_error_message(GameManager.join_error_code()) :: String.t()
  def get_join_error_message(error_code) do
    case error_code do
      :already_exists -> "Player already exists"
      :not_found -> "Game not found"
      :not_joinable -> "Game not joinable"
    end
  end

  @spec any_missing_player_round_score?(GameManager.game()) :: boolean()
  def any_missing_player_round_score?(game) do
    not Enum.all?(game.scores, fn {_player, player_scores} ->
      Map.has_key?(player_scores, to_string(game.round))
    end)
  end

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
