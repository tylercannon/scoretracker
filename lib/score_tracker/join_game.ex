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

  @primary_key false
  embedded_schema do
    field :player_name, :string
    field :game_id, :string
  end

  @spec changeset(struct()) :: Ecto.Changeset.t()
  @spec changeset(struct(), map()) :: Ecto.Changeset.t()
  def changeset(join_game, attrs \\ %{}) do
    join_game
    |> cast(attrs, [:player_name, :game_id])
    |> validate_required([:player_name, :game_id])
    |> validate_player_name(:player_name)
    |> update_change(:game_id, &String.upcase/1)
  end

  def update(%__MODULE__{} = join_game, attrs) do
    join_game
    |> changeset(attrs)
    |> apply_action(:update)
  end
end
