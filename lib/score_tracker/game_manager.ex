defmodule ScoreTracker.GameManager do
  @moduledoc """
  Module responsible for maintaining the state of
  every game and persisting that state to storage
  """

  use GenServer

  alias ScoreTracker.{Game, GameType}

  @table_name :lobbies

  @create_game_schema NimbleOptions.new!(
                        allow_spectators: [
                          type: :boolean,
                          required: false,
                          default: true,
                          doc: "Whether spectators are allowed to view the game."
                        ],
                        custom_name: [
                          type: {:or, [:string, nil]},
                          required: false,
                          doc: "The optional custom game name when the game type is :custom"
                        ],
                        game_mode: [
                          type: {:in, [:scorekeeper, :party]},
                          required: true,
                          doc: """
                          The game mode of the game.
                          In scorekeeper mode, the host updates each players score and players can join the game as a view-only user.
                          In party mode, each player joins the game and updates their own scores.
                          """
                        ],
                        game_type: [
                          type: {:in, GameType.game_types()},
                          required: true,
                          doc: """
                          The game type.
                          Each type of game has custom settings, such as the maximum number of players or rounds.
                          """
                        ],
                        host_id: [
                          type: :string,
                          required: true,
                          doc: "The id of the host."
                        ],
                        host_name: [
                          type: :string,
                          required: true,
                          doc: "The name of the host. Automatically added to the list of players."
                        ],
                        max_players: [
                          type: :pos_integer,
                          required: true,
                          doc: "The maximum number of players that can join the game."
                        ],
                        max_rounds: [
                          type: :pos_integer,
                          required: true,
                          doc: "The maximum number of rounds in the game."
                        ],
                        players: [
                          type: {:list, :string},
                          required: false,
                          default: [],
                          doc:
                            "The list of players (excluding the host) that aren't updating their own scores."
                        ],
                        winning_score_type: [
                          type: {:in, GameType.score_types()},
                          required: true,
                          doc: """
                          The winning score type.
                          """
                        ]
                      )

  @add_player_schema NimbleOptions.new!(
                       game_id: [
                         type: :string,
                         required: true,
                         doc: "The game id to add the player to."
                       ],
                       player_id: [
                         type: :string,
                         required: true,
                         doc: "The id of the player to add to the game."
                       ],
                       player_name: [
                         type: :string,
                         required: true,
                         doc: "The name of the player to add to the game."
                       ]
                     )

  @update_player_score_schema NimbleOptions.new!(
                                game_id: [
                                  type: :string,
                                  required: true,
                                  doc: "The game id of the game."
                                ],
                                player_id: [
                                  type: :string,
                                  required: true,
                                  doc: "The name of the player to update the score for."
                                ],
                                round: [
                                  type: :pos_integer,
                                  required: true,
                                  doc: "The round of the game to update the player's score for."
                                ],
                                score: [
                                  type: :integer,
                                  required: true,
                                  doc: "The player's score for the given round."
                                ]
                              )

  @start_game_schema NimbleOptions.new!(
                       game_id: [
                         type: :string,
                         required: true,
                         doc: "The game id of the game."
                       ]
                     )

  @advance_round_schema NimbleOptions.new!(
                          game_id: [
                            type: :string,
                            required: true,
                            doc: "The game id of the game."
                          ]
                        )

  @reset_game_schema NimbleOptions.new!(
                       game_id: [
                         type: :string,
                         required: true,
                         doc: "The game id of the game."
                       ]
                     )

  @type create_game_opts() :: [unquote(NimbleOptions.option_typespec(@create_game_schema))]
  @type add_player_opts() :: [unquote(NimbleOptions.option_typespec(@add_player_schema))]

  @type update_player_score_opts() :: [
          unquote(NimbleOptions.option_typespec(@update_player_score_schema))
        ]

  @type start_game_opts() :: [unquote(NimbleOptions.option_typespec(@start_game_schema))]
  @type advance_round_opts() :: [unquote(NimbleOptions.option_typespec(@advance_round_schema))]
  @type reset_game_opts() :: [unquote(NimbleOptions.option_typespec(@reset_game_schema))]

  # Client API

  def start_link(opts \\ []) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec create_game(game_manager :: module(), game_opts :: create_game_opts()) ::
          String.t() | {:error, NimbleOptions.ValidationError.t()}
  def create_game(game_manager, game_opts) do
    case NimbleOptions.validate(game_opts, @create_game_schema) do
      {:ok, game_opts} ->
        GenServer.call(game_manager, {:create_game, game_opts})

      error ->
        error
    end
  end

  @spec add_player(game_manager :: module(), player_opts :: add_player_opts()) ::
          :ok | {:error, Game.join_error_code() | NimbleOptions.ValidationError.t()}
  def add_player(game_manager, player_opts) do
    case NimbleOptions.validate(player_opts, @add_player_schema) do
      {:ok, player_opts} ->
        GenServer.call(game_manager, {:add_player, player_opts})

      error ->
        error
    end
  end

  @spec update_player_score(game_manager :: module(), score_opts :: update_player_score_opts()) ::
          :ok | {:error, :not_found | :player_not_found | NimbleOptions.ValidationError.t()}
  def update_player_score(game_manager, score_opts) do
    case NimbleOptions.validate(score_opts, @update_player_score_schema) do
      {:ok, score_opts} ->
        GenServer.call(game_manager, {:update_player_score, score_opts})

      error ->
        error
    end
  end

  @spec start_game(game_manager :: module(), start_opts :: start_game_opts()) ::
          {:ok, Game.status()}
          | {:error, :not_found | Game.start_error_code() | NimbleOptions.ValidationError.t()}
  def start_game(game_manager, start_opts) do
    case NimbleOptions.validate(start_opts, @start_game_schema) do
      {:ok, opts} ->
        GenServer.call(game_manager, {:start_game, opts})

      error ->
        error
    end
  end

  @spec advance_to_next_round(game_manager :: module(), round_opts :: advance_round_opts()) ::
          {:ok, non_neg_integer()}
          | {:error, :not_found | :max_rounds_reached | NimbleOptions.ValidationError.t()}
  def advance_to_next_round(game_manager, round_opts) do
    case NimbleOptions.validate(round_opts, @advance_round_schema) do
      {:ok, opts} ->
        GenServer.call(game_manager, {:advance_to_next_round, opts})

      error ->
        error
    end
  end

  @spec reset_game(game_manager :: module(), reset_opts :: reset_game_opts()) ::
          :ok | {:error, :not_found | :invalid_game_state | NimbleOptions.ValidationError.t()}
  def reset_game(game_manager, reset_opts) do
    case NimbleOptions.validate(reset_opts, @reset_game_schema) do
      {:ok, opts} ->
        GenServer.call(game_manager, {:reset_game, opts})

      error ->
        error
    end
  end

  @spec get_game(game_manager :: module(), game_id :: String.t()) ::
          {:ok, Game.t()} | {:error, :not_found}
  def get_game(game_manager, game_id) do
    GenServer.call(game_manager, {:get_game, game_id})
  end

  # Server callbacks

  @impl true
  def init(opts) do
    storage_mod = Keyword.fetch!(opts, :storage_backend)
    storage_opts = Keyword.fetch!(opts, :storage_backend_opts)
    table_id = storage_mod.init(@table_name, storage_opts)

    {:ok, %{storage_mod: storage_mod, table_id: table_id}}
  end

  @impl true
  def handle_call({:create_game, game_opts}, _from, state) do
    %{storage_mod: storage_mod, table_id: table_id} = state

    game_id = generate_game_id(storage_mod, table_id)
    game = Game.new(game_opts)

    storage_mod.save_state(table_id, game_id, game)

    {:reply, game_id, state}
  end

  @impl true
  def handle_call({:add_player, player_opts}, _from, state) do
    %{storage_mod: storage_mod, table_id: table_id} = state

    game_id = Keyword.get(player_opts, :game_id)
    player_id = Keyword.get(player_opts, :player_id)
    player_name = Keyword.get(player_opts, :player_name)

    case storage_mod.get_game(table_id, game_id) do
      {:ok, game} ->
        result =
          case Game.add_player(game, player_id, player_name) do
            {:ok, :spectator, _game} ->
              :ok

            {:ok, :player, updated_game} ->
              storage_mod.save_state(table_id, game_id, updated_game)
              :ok

            {:error, reason} ->
              {:error, reason}
          end

        {:reply, result, state}

      _ ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:update_player_score, score_opts}, _from, state) do
    %{storage_mod: storage_mod, table_id: table_id} = state

    game_id = Keyword.get(score_opts, :game_id)
    player_id = Keyword.get(score_opts, :player_id)
    round = Keyword.get(score_opts, :round)
    score = Keyword.get(score_opts, :score)

    case storage_mod.get_game(table_id, game_id) do
      {:ok, game} ->
        result =
          case Game.update_score(game, player_id, round, score) do
            {:ok, updated_game} ->
              storage_mod.save_state(table_id, game_id, updated_game)
              :ok

            {:error, reason} ->
              {:error, reason}
          end

        {:reply, result, state}

      _ ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:start_game, opts}, _from, state) do
    %{storage_mod: storage_mod, table_id: table_id} = state

    game_id = Keyword.get(opts, :game_id)

    case storage_mod.get_game(table_id, game_id) do
      {:ok, game} ->
        result =
          case Game.start(game) do
            {:ok, updated_game} ->
              storage_mod.save_state(table_id, game_id, updated_game)
              {:ok, updated_game.status}

            {:error, reason} ->
              {:error, reason}
          end

        {:reply, result, state}

      _ ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:advance_to_next_round, opts}, _from, state) do
    %{storage_mod: storage_mod, table_id: table_id} = state

    game_id = Keyword.get(opts, :game_id)

    case storage_mod.get_game(table_id, game_id) do
      {:ok, game} ->
        updated_game = Game.advance_round(game)
        storage_mod.save_state(table_id, game_id, updated_game)

        {:reply, {:ok, updated_game.round}, state}

      _ ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:reset_game, opts}, _from, state) do
    %{storage_mod: storage_mod, table_id: table_id} = state

    game_id = Keyword.get(opts, :game_id)

    case storage_mod.get_game(table_id, game_id) do
      {:ok, game} ->
        result =
          case Game.reset(game) do
            {:ok, updated_game} ->
              storage_mod.save_state(table_id, game_id, updated_game)
              :ok

            {:error, reason} ->
              {:error, reason}
          end

        {:reply, result, state}

      _ ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:get_game, game_id}, _from, state) do
    %{storage_mod: storage_mod, table_id: table_id} = state

    case storage_mod.get_game(table_id, game_id) do
      {:ok, game_state} ->
        {:reply, {:ok, game_state}, state}

      _ ->
        {:reply, {:error, :not_found}, state}
    end
  end

  # Private helpers

  defp generate_game_id(storage_mod, table_id, len \\ 8) do
    allowed_characters = ~c"ABCDEFGHJKMNPQRTUVWXYZ2346789"
    game_id_characters = for _ <- 1..len, into: [], do: Enum.random(allowed_characters)
    game_id = to_string(game_id_characters)

    case storage_mod.get_game(table_id, game_id) do
      {:ok, _} -> generate_game_id(storage_mod, table_id, len)
      _ -> game_id
    end
  end
end
