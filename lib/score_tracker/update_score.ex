defmodule ScoreTracker.UpdateScore do
  use Ecto.Schema
  use ScoreTracker.Changeset

  @type t :: %__MODULE__{
          score: non_neg_integer()
        }

  @primary_key false
  embedded_schema do
    field :score, :integer
  end

  @spec changeset(struct(), atom()) :: Ecto.Changeset.t()
  @spec changeset(struct(), atom(), map()) :: Ecto.Changeset.t()
  def changeset(update_score, game_type, attrs \\ %{}) do
    update_score
    |> cast(attrs, [:score])
    |> validate_required([:score])
    |> validate_round_score(:score, game_type)
  end

  def update(%__MODULE__{} = update_score, game_type, attrs) do
    update_score
    |> changeset(game_type, attrs)
    |> apply_action(:update)
  end
end
