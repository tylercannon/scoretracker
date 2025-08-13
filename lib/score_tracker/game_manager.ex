defmodule ScoreTracker.GameManager do
  use GenServer

  @table_name :lobbies

  @create_game_schema NimbleOptions.new!(
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
                        game_mode: [
                          type: {:in, [:scorekeeper, :party]},
                          required: true,
                          doc: """
                          The game mode of the game.
                          In scorekeeper mode, the host updates each players score and players can join the game as a view-only user.
                          In party mode, each player joins the game and updates their own scores.
                          """
                        ],
                        max_players: [
                          type: :pos_integer,
                          required: false,
                          default: 6,
                          doc: "The maximum number of players that can join the game."
                        ],
                        max_rounds: [
                          type: :pos_integer,
                          required: false,
                          default: 10,
                          doc: "The maximum number of rounds in the game."
                        ],
                        players: [
                          type: {:list, :string},
                          required: false,
                          default: [],
                          doc:
                            "The list of players (excluding the host) that aren't updating their own scores."
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

  @advance_round_schema NimbleOptions.new!(
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

  @type advance_round_opts() :: [unquote(NimbleOptions.option_typespec(@advance_round_schema))]

  @type status() :: :in_progress | :waiting_for_players

  @type game() :: %{
          max_players: non_neg_integer(),
          max_rounds: non_neg_integer(),
          host_id: String.t(),
          status: status(),
          round: non_neg_integer(),
          player_names: map(),
          scores: map()
        }

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec create_game(create_game_opts()) ::
          String.t() | {:error, NimbleOptions.ValidationError.t()}
  def create_game(game_opts) do
    with {:ok, game_opts} <- NimbleOptions.validate(game_opts, @create_game_schema) do
      GenServer.call(__MODULE__, {:create_game, game_opts})
    else
      error -> error
    end
  end

  @spec add_player(add_player_opts()) ::
          :ok | {:error, :already_exists | :not_found | NimbleOptions.ValidationError.t()}
  def add_player(player_opts) do
    with {:ok, player_opts} <- NimbleOptions.validate(player_opts, @add_player_schema) do
      GenServer.call(__MODULE__, {:add_player, player_opts})
    else
      error -> error
    end
  end

  @spec update_player_score(update_player_score_opts()) ::
          :ok | {:error, :not_found | NimbleOptions.ValidationError.t()}
  def update_player_score(score_opts) do
    with {:ok, score_opts} <- NimbleOptions.validate(score_opts, @update_player_score_schema) do
      GenServer.call(__MODULE__, {:update_player_score, score_opts})
    else
      error -> error
    end
  end

  @spec advance_to_next_round(advance_round_opts()) ::
          {:ok, non_neg_integer()}
          | {:error, :not_found | :max_rounds_reached | NimbleOptions.ValidationError.t()}
  def advance_to_next_round(opts) do
    with {:ok, opts} <- NimbleOptions.validate(opts, []) do
      GenServer.call(__MODULE__, {:advance_to_next_round, opts})
    else
      error -> error
    end
  end

  @spec get_game(String.t()) :: {:ok, game()} | {:error, :not_found}
  def get_game(game_id) do
    case :ets.lookup(@table_name, game_id) do
      [{^game_id, game_state}] -> {:ok, game_state}
      [] -> {:error, :not_found}
    end
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    table_id = :ets.new(@table_name, [:set, :public, :named_table, {:write_concurrency, true}])
    {:ok, table_id}
  end

  @impl true
  def handle_call({:create_game, game_opts}, _from, table_id) do
    game_id = generate_game_id()
    host_id = Keyword.get(game_opts, :host_id)
    host_name = Keyword.get(game_opts, :host_name)
    game_mode = Keyword.get(game_opts, :game_mode)
    player_names = Map.put(%{}, host_id, host_name)
    players = [host_id | Keyword.get(game_opts, :players, [])]
    status = if game_mode == :scorekeeper, do: :in_progress, else: :waiting_for_players

    scores =
      Enum.reduce(players, %{}, fn player, acc ->
        Map.put(acc, player, %{"1" => 0})
      end)

    initial_state = %{
      max_players: Keyword.get(game_opts, :max_players, 6),
      max_rounds: Keyword.get(game_opts, :max_rounds, 10),
      host_id: host_id,
      status: status,
      round: 1,
      player_names: player_names,
      scores: scores
    }

    :ets.insert(table_id, {game_id, initial_state})

    {:reply, game_id, table_id}
  end

  @impl true
  def handle_call({:add_player, player_opts}, _from, table_id) do
    game_id = Keyword.get(player_opts, :game_id)
    player_id = Keyword.get(player_opts, :player_id)
    player_name = Keyword.get(player_opts, :player_name)

    case :ets.lookup(table_id, game_id) do
      [{^game_id, game_state}] ->
        case Map.has_key?(game_state.player_names, player_id) do
          true ->
            {:reply, {:error, :already_exists}, table_id}

          false ->
            updated_scores = Map.put(game_state.scores, player_id, %{"1" => 0})
            updated_player_names = Map.put(game_state.player_names, player_id, player_name)

            updated_game_state =
              game_state
              |> Map.put(:scores, updated_scores)
              |> Map.put(:player_names, updated_player_names)

            :ets.insert(table_id, {game_id, updated_game_state})
            {:reply, :ok, table_id}
        end

      _ ->
        {:reply, {:error, :not_found}, table_id}
    end
  end

  @impl true
  def handle_call({:update_player_score, score_opts}, _from, table_id) do
    game_id = Keyword.get(score_opts, :game_id)
    player_id = Keyword.get(score_opts, :player_id)
    round = Keyword.get(score_opts, :round)
    score = Keyword.get(score_opts, :score)

    case :ets.lookup(table_id, game_id) do
      [{^game_id, game_state}] ->
        updated_player_scores =
          game_state.scores
          |> Map.get(player_id)
          |> Map.put(to_string(round), score)

        updated_scores = Map.put(game_state.scores, player_id, updated_player_scores)
        updated_game_state = %{game_state | scores: updated_scores}
        :ets.insert(table_id, {game_id, updated_game_state})

        {:reply, :ok, table_id}

      _ ->
        {:reply, {:error, :not_found}, table_id}
    end
  end

  def handle_call({:advance_to_next_round, opts}, _from, table_id) do
    game_id = Keyword.get(opts, :game_id)

    case :ets.lookup(table_id, game_id) do
      [{^game_id, game_state}] ->
        round = game_state.round + 1

        if round <= game_state.max_rounds do
          updated_game_state = %{game_state | round: round}
          :ets.insert(table_id, {game_id, updated_game_state})

          {:reply, {:ok, round}, table_id}
        else
          {:reply, {:error, :max_rounds_reached}, table_id}
        end

      _ ->
        {:reply, {:error, :not_found}, table_id}
    end
  end

  # Private helpers

  defp generate_game_id(len \\ 8) do
    allowed_characters = ~c"ABCDEFGHJKMNPQRTUVWXYZ2346789"
    game_id_characters = for _ <- 1..len, into: [], do: Enum.random(allowed_characters)
    game_id = to_string(game_id_characters)

    case :ets.lookup(@table_name, game_id) do
      [] -> game_id
      _ -> generate_game_id(len)
    end
  end
end
