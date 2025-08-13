defmodule ScoreTracker.JoinGame do
  use Ecto.Schema
  import Ecto.Changeset

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
    |> validate_length(:player_name, min: 1, max: 12)
    |> validate_format(:player_name, ~r/^[A-Za-z]*$/)
    |> update_change(:game_id, &String.upcase/1)
  end

  def update(%__MODULE__{} = join_game, attrs) do
    join_game
    |> changeset(attrs)
    |> apply_action(:update)
  end
end
