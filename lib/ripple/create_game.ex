defmodule Ripple.CreateGame do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          host: String.t(),
          game_mode: :scorekeeper | :party,
          max_players: non_neg_integer(),
          max_rounds: non_neg_integer()
        }

  @primary_key false
  embedded_schema do
    field :host, :string
    field :game_mode, Ecto.Enum, values: [:scorekeeper, :party]
    field :max_players, :integer, default: 6
    field :max_rounds, :integer, default: 10
  end

  @spec changeset(struct()) :: Ecto.Changeset.t()
  @spec changeset(struct(), map()) :: Ecto.Changeset.t()
  def changeset(create_game, attrs \\ %{}) do
    create_game
    |> cast(attrs, [:host, :game_mode, :max_players, :max_rounds])
    |> validate_required([:host, :game_mode])
    |> validate_length(:host, min: 1, max: 12)
    |> validate_format(:host, ~r/^[A-Za-z]*$/)
    |> validate_number(:max_players, greater_than_or_equal_to: 2, less_than_or_equal_to: 10)
    |> validate_number(:max_rounds, greater_than_or_equal_to: 1, less_than_or_equal_to: 20)
  end
end
