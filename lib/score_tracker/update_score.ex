defmodule ScoreTracker.UpdateScore do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          score: non_neg_integer()
        }

  @primary_key false
  embedded_schema do
    field :score, :integer
  end

  @spec changeset(struct()) :: Ecto.Changeset.t()
  @spec changeset(struct(), map()) :: Ecto.Changeset.t()
  def changeset(update_score, attrs \\ %{}) do
    update_score
    |> cast(attrs, [:score])
    |> validate_required([:score])
    # number of columns is 5
    # worst possible column score is 29 (15 + 14)
    # worst possible round score is:
    # worst possible column score * number of columns
    # best possible score is a block of 6 of the same card (-50)
    |> validate_number(:score, greater_than_or_equal_to: -50, less_than_or_equal_to: 145)
  end

  def update(%__MODULE__{} = update_score, attrs) do
    update_score
    |> changeset(attrs)
    |> apply_action(:update)
  end
end
