defmodule ScoreTracker.GameType.Rummy do
  @moduledoc """
  Game rules and validation functions
  for the rummy game type
  """

  @behaviour ScoreTracker.GameType

  @prefix "* Objective:"
  @wild_cards "* Wild Cards: 2s and Jokers"
  @round_info %{
    "1" => ["#{@prefix} 2 three of a kinds"],
    "2" => ["#{@prefix} 1 three of a kind and 1 four card run"],
    "3" => ["#{@prefix} 2 four card runs"],
    "4" => ["#{@prefix} 3 three of a kinds"],
    "5" => ["#{@prefix} 2 three of a kinds and 1 four card run"],
    "6" => ["#{@prefix} 1 three of a kind and 2 four card runs"],
    "7" => ["#{@prefix} 3 four card runs"],
    "8" => ["#{@prefix} 4 three of a kinds"]
  }

  @impl ScoreTracker.GameType
  def allows_negative_scores?, do: false

  @impl ScoreTracker.GameType
  def friendly_name, do: "Rummy"

  @impl ScoreTracker.GameType
  def max_players, do: 8

  @impl ScoreTracker.GameType
  def max_rounds, do: 8

  @impl ScoreTracker.GameType
  def round_info(round) do
    @round_info
    |> Map.get(to_string(round))
    |> Enum.concat([@wild_cards])
  end

  @impl ScoreTracker.GameType
  def validate_round_score(changeset, field) do
    # Worst possible score can vary depending on:
    #   * The number of cards in the player's hand
    #   * How many players are in the game (since this affects the total cards available to the player)
    #   * Card values (20 for wild, 15 for ace, 10 for face cards, 5 for any other card)
    # Because of this, set a large value that players should realistically not hit
    # Best possible score is 0 (First player to get rid of all of their cards)
    changeset
    |> Ecto.Changeset.validate_number(field,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 1000
    )
    |> Ecto.Changeset.validate_change(field, fn field, value ->
      if rem(value, 5) == 0 do
        []
      else
        Keyword.new([{field, "must be a multiple of 5"}])
      end
    end)
  end
end
