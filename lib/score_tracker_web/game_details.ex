defmodule ScoreTrackerWeb.GameDetails do
  @moduledoc """
  Helper functions related to displaying
  game state in the UI
  """

  alias ScoreTracker.{Game, GameServer, Player}

  @doc """
  The PubSub topic for a game
  """
  @spec topic(String.t()) :: String.t()
  def topic(game_id), do: "game:##{game_id}"

  @doc """
  Get a game by it's id
  """
  @spec get_game(String.t()) :: {:ok, Game.t()} | {:error, :not_found}
  def get_game(game_id), do: GameServer.get_game(game_id)

  @doc """
  Check whether a game is in progress
  """
  @spec in_progress?(Game.t()) :: boolean()
  def in_progress?(game), do: game.status == :in_progress

  @doc """
  Check whether a game is complete
  """
  @spec complete?(Game.t()) :: boolean()
  def complete?(game), do: game.status == :complete

  @doc """
  Check whether a user is the host of a game
  """
  @spec host?(Game.t(), String.t()) :: boolean()
  def host?(game, user_id), do: game.host_id == user_id

  @doc """
  Check whether a user can access a game (either as a player or spectator)
  """
  @spec accessible?(Game.t(), String.t()) :: boolean()
  def accessible?(game, user_id) do
    player? = Enum.any?(game.players, &match?(%Player{id: ^user_id}, &1))
    observable? = in_progress?(game) and game.allow_spectators

    player? or observable?
  end

  @doc """
  Check whether a user's score is editable
  """
  @spec user_score_editable?(Game.t(), String.t(), String.t(), non_neg_integer()) :: boolean()
  def user_score_editable?(game, player_id, user_id, round) do
    cond do
      not in_progress?(game) -> false
      round != game.round -> false
      host?(game, user_id) -> true
      game.game_mode == :party and player_id == user_id -> true
      true -> false
    end
  end

  @doc """
  Get the friendly status of a game
  """
  @spec get_status(Game.status()) :: String.t()
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
  @spec get_join_error_details(Game.join_error_code()) :: {atom(), String.t()}
  def get_join_error_details(error_code) do
    case error_code do
      :already_exists -> {:player_name, "Player already exists"}
      :duplicate_name -> {:player_name, "Please select a different name"}
      :not_found -> {:game_id, "Game not found"}
      :not_joinable -> {:game_id, "Game not joinable"}
    end
  end

  @spec any_missing_player_round_score?(Game.t()) :: boolean()
  def any_missing_player_round_score?(game) do
    not Enum.all?(game.scores, fn {_player, player_scores} ->
      Map.has_key?(player_scores, to_string(game.round))
    end)
  end

  @doc """
  Format the winners of the game
  """
  @spec format_winners(list(String.t())) :: String.t()
  def format_winners(winners) when length(winners) == 2, do: Enum.join(winners, " and ")

  def format_winners([winner | other_winners]) do
    winners = Enum.join(other_winners, ", ")
    Enum.join([winners, winner], ", and ")
  end

  @doc """
  Calculate a player's total score
  """
  @spec player_total_score(String.t(), Game.t()) :: integer()
  def player_total_score(player_id, game) do
    game.scores[player_id]
    |> Map.values()
    |> Enum.sum()
  end

  @doc """
  Determine the winner(s) of the game
  """
  @spec winner(Game.t()) :: map()
  def winner(game) do
    Enum.reduce(game.players, %{}, fn %Player{id: id, name: name}, acc ->
      score_type = game.winning_score_type
      winner_score = Map.get(acc, :score)
      player_score = player_total_score(id, game)

      cond do
        is_nil(winner_score) ->
          %{type: :single, winner: name, score: player_score}

        score_type == :highest and player_score > winner_score ->
          %{type: :single, winner: name, score: player_score}

        score_type == :lowest and player_score < winner_score ->
          %{type: :single, winner: name, score: player_score}

        player_score == winner_score ->
          multiple_winners(acc, name)

        true ->
          acc
      end
    end)
  end

  defp multiple_winners(%{type: :single} = details, name) do
    details
    |> Map.put(:type, :tie)
    |> Map.put(:winners, [details.winner, name])
    |> Map.delete(:winner)
  end

  defp multiple_winners(%{type: :tie} = details, name) do
    Map.put(details, :winners, [name | details.winners])
  end
end
