defmodule ScoreTracker.JoinGame do
  @moduledoc """
  Module defining the schema and
  validation functions used on the
  join game form
  """

  use Ecto.Schema
  use ScoreTracker.Changeset

  @type t :: %__MODULE__{
          player_name: String.t(),
          game_id: String.t()
        }

  @game_id_length 8
  @game_id_format ~r/^[a-zA-Z\d]*$/

  @primary_key false
  embedded_schema do
    field :player_name, :string
    field :game_id, :string
  end

  @doc """
  Validate the supplied game id
  """
  @spec valid_game_id?(String.t() | nil) :: boolean()
  def valid_game_id?(game_id) when is_binary(game_id) do
    String.length(game_id) == @game_id_length and Regex.match?(@game_id_format, game_id)
  end

  def valid_game_id?(_game_id), do: false

  @spec changeset(struct()) :: Ecto.Changeset.t()
  @spec changeset(struct(), map()) :: Ecto.Changeset.t()
  def changeset(join_game, attrs \\ %{}) do
    join_game
    |> cast(attrs, [:player_name, :game_id])
    |> validate_required([:player_name, :game_id])
    |> validate_player_name(:player_name)
    |> validate_length(:game_id, is: @game_id_length)
    |> validate_format(:game_id, @game_id_format)
    |> update_change(:game_id, &String.upcase/1)
  end

  def update(%__MODULE__{} = join_game, attrs) do
    join_game
    |> changeset(attrs)
    |> apply_action(:update)
  end
end
