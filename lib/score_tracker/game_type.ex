defmodule ScoreTracker.GameType do
  @moduledoc """
  Behaviour for game rules and validation
  functions for a built-in game type
  """

  alias Ecto.Changeset
  alias ScoreTracker.GameType.{Ripple, Rummy}

  @type built_in_game_type() :: :ripple | :rummy

  @type game_type() :: built_in_game_type() | :custom

  @doc """
  The maximum number of players supported by the game type
  """
  @callback max_players() :: pos_integer()

  @doc """
  The maximum number of rounds supported by the game type
  """
  @callback max_rounds() :: pos_integer()

  @doc """
  A validation function for validating the round
  score for the game type
  """
  @callback validate_round_score(changeset :: Changeset.t(), field :: atom()) :: Changeset.t()

  @doc """
  Determine whether the supplied game type is a built in game type
  """
  @spec built_in?(game_type :: game_type()) :: boolean()
  def built_in?(game_type) when game_type in [:ripple, :rummy], do: true
  def built_in?(_game_type), do: false

  @doc """
  Get the game type module associated with the given game type
  """
  @spec impl(game_type :: built_in_game_type()) :: module()
  def impl(:ripple), do: Ripple
  def impl(:rummy), do: Rummy
end
