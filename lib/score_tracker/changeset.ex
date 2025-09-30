defmodule ScoreTracker.Changeset do
  @moduledoc """
  Custom validation functions for validations
  that are used throughout the application
  """

  import Ecto.Changeset

  alias ScoreTracker.GameType

  @doc """
  Format the errors in a changeset into
  a more user-friendly representation
  """
  @spec format_errors(Ecto.Changeset.t()) :: %{required(atom()) => list(String.t())}
  def format_errors(changeset) do
    traverse_errors(changeset, fn {msg, opts} ->
      case Map.new(opts) do
        %{validation: :cast, type: type} ->
          "must be of type: #{type}"

        %{validation: :inclusion, enum: enum} ->
          "must be one of: #{enum |> Enum.sort() |> Enum.join(" | ")}"

        %{validation: :format} ->
          "must be valid format"

        opts ->
          format_error_message(msg, opts)
      end
    end)
  end

  @doc """
  Add game information to the changeset
  when a built in game type is selected
  """
  @spec put_built_in_game_info(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def put_built_in_game_info(changeset) do
    game_type = Ecto.Changeset.get_field(changeset, :game_type)

    if GameType.built_in?(game_type) do
      mod = GameType.mod(game_type)

      changeset
      |> put_change(:max_players, mod.max_players())
      |> put_change(:max_rounds, mod.max_rounds())
    else
      changeset
    end
  end

  @doc """
  Validate a player name length and format
  """
  @spec validate_player_name(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_player_name(changeset, field) do
    changeset
    |> validate_length(field, min: 1, max: 12)
    |> validate_format(field, ~r/^[A-Za-z]*$/)
  end

  @doc """
  Validate the round score based on the given game type
  """
  @spec validate_round_score(Ecto.Changeset.t(), atom(), GameType.game_type()) ::
          Ecto.Changeset.t()
  def validate_round_score(changeset, field, game_type) do
    if GameType.built_in?(game_type) do
      mod = GameType.mod(game_type)

      mod.validate_round_score(changeset, field)
    else
      changeset
    end
  end

  defmacro __using__([]) do
    quote do
      import Ecto.Changeset
      import ScoreTracker.Changeset
    end
  end

  defp format_error_message(message, opts) do
    Regex.replace(~r"%{(\w+)}", message, fn _, key ->
      opts
      |> Map.get(String.to_existing_atom(key), key)
      |> to_string()
    end)
  end
end
