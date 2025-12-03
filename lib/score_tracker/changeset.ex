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
      impl = GameType.impl(game_type)

      changeset
      |> put_change(:max_players, impl.max_players())
      |> put_change(:max_rounds, impl.max_rounds())
    else
      changeset
    end
  end

  @doc """
  Validate the custom game name if supplied
  when the game type selected is `:custom`
  """
  @spec validate_custom_name(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_custom_name(changeset) do
    if get_field(changeset, :game_type) == :custom do
      changeset
      |> validate_length(:custom_name, min: 1, max: 12)
      |> validate_format(:custom_name, ~r/^[A-Za-z\d\s]*$/)
    else
      changeset
    end
  end

  @doc """
  Validate that the number of players in the changeset
  (including the host) does not exceed the max players limit
  """
  @spec validate_max_players(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_max_players(changeset) do
    players = get_embed(changeset, :players)
    max_players = get_field(changeset, :max_players)
    player_count = Enum.count(players)

    # Count host as a valid player too
    if player_count > max_players - 1 do
      {valid_players, [invalid_player]} = Enum.split(players, -1)
      invalid_player = add_error(invalid_player, :name, "must not exceed max player count")
      updated_players = Enum.concat(valid_players, [invalid_player])

      put_embed(changeset, :players, updated_players)
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
  Validate that all player names are unique
  """
  @spec validate_unique_player_names(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_unique_player_names(changeset) do
    players = get_embed(changeset, :players)
    host_name = get_field(changeset, :host_name)
    initial = %{names: MapSet.new([host_name]), changesets: []}

    players =
      players
      |> Enum.reduce(initial, fn changeset, %{names: names, changesets: changesets} = acc ->
        name = get_field(changeset, :name)

        cond do
          is_nil(name) ->
            %{acc | changesets: Enum.concat(changesets, [changeset])}

          MapSet.member?(names, name) ->
            updated_changeset = add_error(changeset, :name, "must be unique")
            %{acc | changesets: Enum.concat(changesets, [updated_changeset])}

          true ->
            %{names: MapSet.put(names, name), changesets: Enum.concat(changesets, [changeset])}
        end
      end)
      |> Map.get(:changesets)

    put_embed(changeset, :players, players)
  end

  @doc """
  Validate the round score based on the given game type
  """
  @spec validate_round_score(Ecto.Changeset.t(), atom(), GameType.game_type()) ::
          Ecto.Changeset.t()
  def validate_round_score(changeset, field, game_type) do
    if GameType.built_in?(game_type) do
      impl = GameType.impl(game_type)
      impl.validate_round_score(changeset, field)
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
