defmodule ScoreTracker.GameServer do
  @moduledoc """
  A per-game GenServer process that holds game state in memory.

  Each game gets its own process, started on demand via `ScoreTracker.GameSupervisor`.
  Game lookup is handled via `ScoreTracker.GameRegistry`.

  Game state is persisted asynchronously after modifications.
  A periodic timer persists state on a fixed interval and `terminate/2`
  performs a final persist before shutdown.

  Idle game processes shut down after a period of inactivity.
  """

  use GenServer, restart: :transient, shutdown: 10_000

  alias ScoreTracker.Game

  @hibernate_after :timer.seconds(60)
  @idle_timeout :timer.hours(1)
  @persist_interval :timer.seconds(15)

  @max_id_retries 3

  defmodule State do
    @moduledoc false

    @type t :: %__MODULE__{
            game_id: String.t(),
            game: Game.t() | nil,
            storage_mod: module(),
            dirty: boolean()
          }

    @enforce_keys [:game_id, :storage_mod]
    defstruct [:game_id, :game, :storage_mod, dirty: false]
  end

  # Client API

  @doc """
  Start a GameServer process for the given game_id.

  If `game` is provided, the process initializes with the new game state.
  If `game` is `nil`, the process loads the game's state from storage.

  Returns `:ignore` if the game is not found in storage.
  """
  def start_link(opts) do
    game_id = Keyword.fetch!(opts, :game_id)
    game = Keyword.get(opts, :game)
    storage_mod = Keyword.fetch!(opts, :storage_mod)

    GenServer.start_link(__MODULE__, {game_id, game, storage_mod},
      name: via(game_id),
      hibernate_after: @hibernate_after
    )
  end

  @doc """
  Returns the via-tuple for Registry-based process lookup.
  """
  @spec via(String.t()) :: {:via, Registry, {ScoreTracker.GameRegistry, String.t()}}
  def via(game_id), do: {:via, Registry, {ScoreTracker.GameRegistry, game_id}}

  @doc """
  Create a new game, starting a GameServer process for it.
  Returns `game_id` on success.
  """
  @spec create_game(keyword()) :: String.t() | {:error, term()}
  def create_game(game_opts), do: create_game(game_opts, @max_id_retries)

  @doc """
  Get the game state from the GameServer process.
  """
  @spec get_game(String.t()) :: {:ok, Game.t()} | {:error, :not_found}
  def get_game(game_id), do: call_game(game_id, :get_game)

  @doc """
  Add a player to the game.

  ## Options

    * `:game_id` - The game id to add the player to (required)
    * `:player_id` - The id of the player to add (required)
    * `:player_name` - The name of the player to add (required)
  """
  @spec add_player(keyword()) :: :ok | {:error, Game.join_error_code() | :not_found}
  def add_player(player_opts) do
    game_id = Keyword.fetch!(player_opts, :game_id)
    player_id = Keyword.fetch!(player_opts, :player_id)
    player_name = Keyword.fetch!(player_opts, :player_name)

    call_game(game_id, {:add_player, player_id, player_name})
  end

  @doc """
  Update a player's score for a given round.

  ## Options

    * `:game_id` - The game id of the game (required)
    * `:player_id` - The id of the player to update the score for (required)
    * `:round` - The round to update the score for (required)
    * `:score` - The player's score for the given round (required)
  """
  @spec update_player_score(keyword()) :: :ok | {:error, :not_found | :player_not_found}
  def update_player_score(opts) do
    game_id = Keyword.fetch!(opts, :game_id)
    player_id = Keyword.fetch!(opts, :player_id)
    round = Keyword.fetch!(opts, :round)
    score = Keyword.fetch!(opts, :score)

    call_game(game_id, {:update_player_score, player_id, round, score})
  end

  @doc """
  Start the game (party mode only).
  """
  @spec start_game(String.t()) ::
          {:ok, Game.status()} | {:error, :not_found | Game.start_error_code()}
  def start_game(game_id), do: call_game(game_id, :start_game)

  @doc """
  Advance the game to the next round.
  """
  @spec advance_to_next_round(String.t()) ::
          {:ok, non_neg_integer()} | {:error, :not_found}
  def advance_to_next_round(game_id), do: call_game(game_id, :advance_to_next_round)

  @doc """
  Reset the game back to its initial state.
  """
  @spec reset_game(String.t()) ::
          :ok | {:error, :not_found | :invalid_game_state}
  def reset_game(game_id), do: call_game(game_id, :reset_game)

  # Server Callbacks

  @impl GenServer
  def init({game_id, nil, storage_mod}) do
    case storage_mod.get_game(game_id) do
      {:ok, game} ->
        Process.flag(:trap_exit, true)
        schedule_persist()

        state = %State{game_id: game_id, game: game, storage_mod: storage_mod}

        {:ok, state, @idle_timeout}

      {:error, :not_found} ->
        :ignore
    end
  end

  @impl GenServer
  def init({game_id, %Game{} = game, storage_mod}) do
    Process.flag(:trap_exit, true)
    schedule_persist()

    state = %State{game_id: game_id, game: game, storage_mod: storage_mod, dirty: true}

    {:ok, state, {:continue, :persist}}
  end

  @impl GenServer
  def handle_continue(:persist, %State{} = state) do
    persist(state)
    {:noreply, %{state | dirty: false}, @idle_timeout}
  end

  @impl GenServer
  def handle_call(:get_game, _from, %State{} = state) do
    {:reply, {:ok, state.game}, state, @idle_timeout}
  end

  @impl GenServer
  def handle_call({:add_player, player_id, player_name}, _from, %State{} = state) do
    case Game.add_player(state.game, player_id, player_name) do
      {:ok, :spectator, _game} ->
        {:reply, :ok, state, @idle_timeout}

      {:ok, :player, updated_game} ->
        new_state = %{state | game: updated_game, dirty: true}

        {:reply, :ok, new_state, {:continue, :persist}}

      {:error, reason} ->
        {:reply, {:error, reason}, state, @idle_timeout}
    end
  end

  @impl GenServer
  def handle_call({:update_player_score, player_id, round, score}, _from, %State{} = state) do
    case Game.update_score(state.game, player_id, round, score) do
      {:ok, updated_game} ->
        new_state = %{state | game: updated_game, dirty: true}

        {:reply, :ok, new_state, {:continue, :persist}}

      {:error, reason} ->
        {:reply, {:error, reason}, state, @idle_timeout}
    end
  end

  @impl GenServer
  def handle_call(:start_game, _from, %State{} = state) do
    case Game.start(state.game) do
      {:ok, updated_game} ->
        new_state = %{state | game: updated_game, dirty: true}

        {:reply, {:ok, updated_game.status}, new_state, {:continue, :persist}}

      {:error, reason} ->
        {:reply, {:error, reason}, state, @idle_timeout}
    end
  end

  @impl GenServer
  def handle_call(:advance_to_next_round, _from, %State{} = state) do
    updated_game = Game.advance_round(state.game)
    new_state = %{state | game: updated_game, dirty: true}

    {:reply, {:ok, updated_game.round}, new_state, {:continue, :persist}}
  end

  @impl GenServer
  def handle_call(:reset_game, _from, %State{} = state) do
    case Game.reset(state.game) do
      {:ok, updated_game} ->
        new_state = %{state | game: updated_game, dirty: true}

        {:reply, :ok, new_state, {:continue, :persist}}

      {:error, reason} ->
        {:reply, {:error, reason}, state, @idle_timeout}
    end
  end

  @impl GenServer
  def handle_info(:periodic_persist, %State{} = state) do
    if state.dirty do
      persist(state)
    end

    schedule_persist()

    {:noreply, %{state | dirty: false}, @idle_timeout}
  end

  @impl GenServer
  def handle_info(:timeout, %State{} = state) do
    # Idle timeout — shut down to free resources
    {:stop, {:shutdown, :idle_timeout}, state}
  end

  @impl GenServer
  def terminate(_reason, %State{} = state) do
    if state.dirty do
      persist(state)
    end

    :ok
  end

  # Private Helpers

  defp create_game(_game_opts, 0), do: {:error, :id_collision}

  defp create_game(game_opts, retries) do
    game_id = generate_game_id()
    game = Game.new(game_opts)
    storage = storage_mod()

    opts = [game_id: game_id, game: game, storage_mod: storage]

    case DynamicSupervisor.start_child(ScoreTracker.GameSupervisor, {__MODULE__, opts}) do
      {:ok, _pid} -> game_id
      {:ok, _pid, _info} -> game_id
      :ignore -> {:error, :not_started}
      {:error, {:already_started, _pid}} -> create_game(game_opts, retries - 1)
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_started(game_id) do
    case GenServer.whereis(via(game_id)) do
      nil -> start_from_storage(game_id)
      pid when is_pid(pid) -> {:ok, pid}
    end
  end

  defp start_from_storage(game_id) do
    opts = [game_id: game_id, game: nil, storage_mod: storage_mod()]

    case DynamicSupervisor.start_child(ScoreTracker.GameSupervisor, {__MODULE__, opts}) do
      {:ok, pid} -> {:ok, pid}
      {:ok, pid, _info} -> {:ok, pid}
      :ignore -> {:error, :not_found}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, _reason} -> {:error, :not_found}
    end
  end

  defp call_game(game_id, message) do
    case ensure_started(game_id) do
      {:ok, _pid} -> GenServer.call(via(game_id), message)
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  defp persist(%State{game_id: game_id, game: game, storage_mod: storage_mod}) do
    storage_mod.save_state(game_id, game)
  end

  defp schedule_persist do
    Process.send_after(self(), :periodic_persist, @persist_interval)
  end

  defp generate_game_id(len \\ 8) do
    allowed_characters = ~c"ABCDEFGHJKMNPQRTUVWXYZ2346789"
    game_id_characters = for _ <- 1..len, into: [], do: Enum.random(allowed_characters)
    to_string(game_id_characters)
  end

  defp storage_mod do
    Application.get_env(:score_tracker, :game_storage_backend, ScoreTracker.GameStorage.Cache)
  end
end
