defmodule ScoreTracker.Player do
  @moduledoc """
  Module representing a game player.
  This module also defines the validation
  functions used on the create game form
  for handling players participating in a
  scorekeeper-based game
  """

  use Ecto.Schema
  use ScoreTracker.Changeset

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t()
        }

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field :id, :string
    field :name, :string
  end

  @spec changeset(struct()) :: Ecto.Changeset.t()
  @spec changeset(struct(), map()) :: Ecto.Changeset.t()
  def changeset(player, attrs \\ %{}) do
    player
    |> cast(attrs, [:name])
    |> validate_required(:name)
    |> validate_player_name(:name)
  end
end
