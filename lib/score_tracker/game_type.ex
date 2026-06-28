defmodule ScoreTracker.GameType do
  @moduledoc """
  Behaviour for game rules and validation
  functions for a built-in game type
  """

  alias Ecto.Changeset
  alias ScoreTracker.GameType.{FiveCrowns, Ripple, Rummy}

  @type built_in_game_type() :: :five_crowns | :ripple | :rummy

  @type game_type() :: built_in_game_type() | :custom
  @type score_type() :: :highest | :lowest

  @doc """
  Whether the game type supports negative round scores
  """
  @callback allows_negative_scores?() :: boolean()

  @doc """
  The friendly name of the game type
  """
  @callback friendly_name() :: String.t()

  @doc """
  The maximum number of players supported by the game type
  """
  @callback max_players() :: pos_integer()

  @doc """
  The maximum number of rounds supported by the game type
  """
  @callback max_rounds() :: pos_integer()

  @doc """
  Round-specific information for the game type
  """
  @callback round_info(round :: non_neg_integer()) :: list(String.t())

  @doc """
  A validation function for validating the round
  score for the game type
  """
  @callback validate_round_score(changeset :: Changeset.t(), field :: atom()) :: Changeset.t()

  @doc """
  Whether the winner needs the highest or lowest score to win for the game type
  """
  @callback winning_score_type() :: score_type()

  @doc """
  Returns a list of all built-in game types
  """
  @spec built_in_types() :: [built_in_game_type()]
  def built_in_types, do: [:five_crowns, :ripple, :rummy]

  @doc """
  Returns a list of all game types
  """
  @spec game_types() :: [game_type()]
  def game_types, do: built_in_types() ++ [:custom]

  @doc """
  Returns a list of all score types
  """
  @spec score_types() :: [score_type()]
  def score_types, do: [:highest, :lowest]

  @doc """
  Returns whether the game type supports negative round scores
  """
  @spec allows_negative_scores?(game_type()) :: boolean()
  def allows_negative_scores?(:custom), do: true
  def allows_negative_scores?(game_type), do: impl(game_type).allows_negative_scores?()

  @doc """
  Returns the custom game name for custom game types,
  or the friendly name otherwise
  """
  @spec friendly_name(game_type(), String.t() | nil) :: String.t()
  def friendly_name(:custom, custom_name) when is_binary(custom_name), do: custom_name
  def friendly_name(game_type, _custom_name), do: friendly_name(game_type)

  @doc """
  Returns the friendly name for a game type
  """
  @spec friendly_name(game_type()) :: String.t()
  def friendly_name(:custom), do: "Custom Game"
  def friendly_name(game_type), do: impl(game_type).friendly_name()

  @doc """
  Returns the friendly name for a score type
  """
  @spec friendly_score_type(score_type()) :: String.t()
  def friendly_score_type(score_type) do
    score_type
    |> Atom.to_string()
    |> String.capitalize()
    |> Kernel.<>(" Score")
  end

  @doc """
  Returns round-specific info for the given game type
  """
  @spec round_info(game_type(), non_neg_integer()) :: list(String.t()) | nil
  def round_info(:custom, _round), do: nil
  def round_info(game_type, round), do: impl(game_type).round_info(round)

  @doc """
  Determine whether the supplied game type is a built in game type
  """
  @spec built_in?(game_type :: game_type()) :: boolean()
  def built_in?(game_type), do: game_type in built_in_types()

  @doc """
  Returns the default game configuration
  """
  @spec default_game() :: map()
  def default_game do
    default_game_type = :rummy
    default_game_impl = impl(default_game_type)

    %{
      type: default_game_type,
      max_players: default_game_impl.max_players(),
      max_rounds: default_game_impl.max_rounds(),
      winning_score_type: default_game_impl.winning_score_type()
    }
  end

  @doc """
  Get the game type module associated with the given game type
  """
  @spec impl(game_type :: built_in_game_type()) :: module()
  def impl(:five_crowns), do: FiveCrowns
  def impl(:ripple), do: Ripple
  def impl(:rummy), do: Rummy
end
