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
  The friendly name of the game type
  """
  @callback friendly_name() :: String.t()

  @doc """
  Whether the game type supports negative round scores
  """
  @callback allows_negative_scores?() :: boolean()

  @doc """
  A validation function for validating the round
  score for the game type
  """
  @callback validate_round_score(changeset :: Changeset.t(), field :: atom()) :: Changeset.t()

  @doc """
  Returns a list of all built-in game types
  """
  @spec built_in_types() :: [built_in_game_type()]
  def built_in_types, do: [:ripple, :rummy]

  @doc """
  Returns a list of all game types
  """
  @spec game_types() :: [game_type()]
  def game_types, do: built_in_types() ++ [:custom]

  @doc """
  Returns whether the game type supports negative round scores
  """
  @spec allows_negative_scores?(game_type()) :: boolean()
  def allows_negative_scores?(:custom), do: true
  def allows_negative_scores?(game_type), do: impl(game_type).allows_negative_scores?()

  @doc """
  Returns the friendly name for a game type
  """
  @spec friendly_name(game_type()) :: String.t()
  def friendly_name(:custom), do: "Custom Game"
  def friendly_name(game_type), do: impl(game_type).friendly_name()

  @doc """
  Determine whether the supplied game type is a built in game type
  """
  @spec built_in?(game_type :: game_type()) :: boolean()
  def built_in?(game_type), do: game_type in built_in_types()

  @doc """
  Returns the default game configuration
  """
  @spec default_game() :: map()
  def default_game,
    do: %{
      type: :ripple,
      max_players: Ripple.max_players(),
      max_rounds: Ripple.max_rounds()
    }

  @doc """
  Get the game type module associated with the given game type
  """
  @spec impl(game_type :: built_in_game_type()) :: module()
  def impl(:ripple), do: Ripple
  def impl(:rummy), do: Rummy
end
