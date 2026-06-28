defmodule ScoreTracker.GameType.FiveCrowns do
  @moduledoc """
  Game rules and validation functions
  for the five crowns game type
  """

  @behaviour ScoreTracker.GameType

  @prefix "* Wild Cards:"
  @round_info %{
    "1" => ["#{@prefix} 3s and Jokers"],
    "2" => ["#{@prefix} 4s and Jokers"],
    "3" => ["#{@prefix} 5s and Jokers"],
    "4" => ["#{@prefix} 6s and Jokers"],
    "5" => ["#{@prefix} 7s and Jokers"],
    "6" => ["#{@prefix} 8s and Jokers"],
    "7" => ["#{@prefix} 9s and Jokers"],
    "8" => ["#{@prefix} 10s and Jokers"],
    "9" => ["#{@prefix} Jacks and Jokers"],
    "10" => ["#{@prefix} Queens and Jokers"],
    "11" => ["#{@prefix} Kings and Jokers"]
  }

  @impl ScoreTracker.GameType
  def allows_negative_scores?, do: false

  @impl ScoreTracker.GameType
  def friendly_name, do: "Five Crowns"

  @impl ScoreTracker.GameType
  def max_players, do: 7

  @impl ScoreTracker.GameType
  def max_rounds, do: 11

  @impl ScoreTracker.GameType
  def round_info(round) do
    Map.get(@round_info, to_string(round))
  end

  @impl ScoreTracker.GameType
  def validate_round_score(changeset, field) do
    # Worst possible score:
    #   * Round 11
    #   * Joker, King, Queen, 10-3
    #   * 50 + 13 + 12 + 10 + 9 + 8 + 7 + 6 + 5 + 4 + 3
    #   * = 127
    Ecto.Changeset.validate_number(changeset, field,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 127
    )
  end

  @impl ScoreTracker.GameType
  def winning_score_type, do: :lowest
end
