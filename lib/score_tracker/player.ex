defmodule ScoreTracker.Player do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          name: String.t()
        }

  @primary_key false
  embedded_schema do
    field :name, :string
  end

  @spec changeset(struct()) :: Ecto.Changeset.t()
  @spec changeset(struct(), map()) :: Ecto.Changeset.t()
  def changeset(player, attrs \\ %{}) do
    player
    |> cast(attrs, [:name])
    |> validate_required(:name)
    |> validate_length(:name, min: 1, max: 12)
    |> validate_format(:name, ~r/^[A-Za-z]*$/)
  end
end
