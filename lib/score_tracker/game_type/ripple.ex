defmodule ScoreTracker.GameType.Ripple do
  @moduledoc """
  Game rules and validation functions
  for the ripple game type
  """

  @behaviour ScoreTracker.GameType

  @impl ScoreTracker.GameType
  def allows_negative_scores?, do: true

  @impl ScoreTracker.GameType
  def friendly_name, do: "Ripple"

  @impl ScoreTracker.GameType
  def max_players, do: 6

  @impl ScoreTracker.GameType
  def max_rounds, do: 10

  @impl ScoreTracker.GameType
  def validate_round_score(changeset, field) do
    # Number of columns is 5
    # Worst possible column score is 29 (15 + 14)
    # Worst possible round score is:
    #   Worst possible column score * Number of columns
    # Best possible score is:
    #   A block of 6 of the same card (-50)
    Ecto.Changeset.validate_number(changeset, field,
      greater_than_or_equal_to: -50,
      less_than_or_equal_to: 145
    )
  end
end
