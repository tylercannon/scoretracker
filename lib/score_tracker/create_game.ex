defmodule ScoreTracker.CreateGame do
  @moduledoc """
  Module defining the schema and
  validation functions used on the
  create game form
  """

  use Ecto.Schema
  use ScoreTracker.Changeset

  alias ScoreTracker.{GameType, Player}

  @type t :: %__MODULE__{
          allow_spectators: boolean(),
          custom_name: String.t() | nil,
          game_mode: :scorekeeper | :party,
          game_type: GameType.game_type(),
          host_name: String.t(),
          max_players: non_neg_integer(),
          max_rounds: non_neg_integer(),
          winning_score_type: GameType.score_type(),
          players: list(Player.t())
        }

  @primary_key false
  embedded_schema do
    field :allow_spectators, :boolean, default: true
    field :custom_name, :string
    field :game_mode, Ecto.Enum, values: [:scorekeeper, :party], default: :scorekeeper

    field :game_type, Ecto.Enum,
      values: GameType.game_types(),
      default: GameType.default_game().type

    field :host_name, :string
    field :max_players, :integer, default: GameType.default_game().max_players
    field :max_rounds, :integer, default: GameType.default_game().max_rounds

    field :winning_score_type, Ecto.Enum,
      values: GameType.score_types(),
      default: GameType.default_game().winning_score_type

    embeds_many :players, Player, on_replace: :delete
  end

  @spec changeset(struct()) :: Ecto.Changeset.t()
  @spec changeset(struct(), map()) :: Ecto.Changeset.t()
  def changeset(create_game, attrs \\ %{}) do
    create_game
    |> cast(attrs, [
      :allow_spectators,
      :custom_name,
      :game_mode,
      :game_type,
      :host_name,
      :max_players,
      :max_rounds,
      :winning_score_type
    ])
    |> cast_embed(:players,
      with: &Player.changeset/2,
      sort_param: :players_sort,
      drop_param: :players_drop
    )
    |> validate_required([:game_mode, :game_type, :host_name])
    |> validate_player_name(:host_name)
    |> validate_unique_player_names()
    |> validate_number(:max_players, greater_than_or_equal_to: 2, less_than_or_equal_to: 10)
    |> validate_number(:max_rounds, greater_than_or_equal_to: 1, less_than_or_equal_to: 20)
    |> validate_max_players()
    |> validate_custom_name()
    |> put_built_in_game_info()
  end

  def update(%__MODULE__{} = create_game, attrs) do
    create_game
    |> changeset(attrs)
    |> apply_action(:update)
  end
end
