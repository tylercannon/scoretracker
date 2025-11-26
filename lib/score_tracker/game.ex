defmodule ScoreTracker.Game do
  @moduledoc """
  This module contains the business logic
  for managing a game
  """

  alias Ecto.UUID
  alias ScoreTracker.GameType

  @type status :: :in_progress | :waiting_for_players | :complete

  @type t :: %__MODULE__{
          game_mode: :scorekeeper | :party,
          game_type: GameType.game_type(),
          allow_spectators: boolean(),
          max_players: non_neg_integer(),
          max_rounds: non_neg_integer(),
          host_id: String.t(),
          status: status(),
          round: non_neg_integer(),
          player_names: %{String.t() => String.t()},
          scores: %{String.t() => %{String.t() => integer()}}
        }

  @derive Jason.Encoder
  defstruct [
    :game_mode,
    :game_type,
    :allow_spectators,
    :max_players,
    :max_rounds,
    :host_id,
    :status,
    :round,
    :player_names,
    :scores
  ]

  @type new_opts :: [
          host_id: String.t(),
          host_name: String.t(),
          game_mode: :scorekeeper | :party,
          game_type: GameType.game_type(),
          allow_spectators: boolean(),
          max_players: pos_integer(),
          max_rounds: pos_integer(),
          players: [String.t()]
        ]

  @type start_error_code() :: :invalid_game_mode | :invalid_game_state
  @type join_error_code() :: :already_exists | :not_found | :not_joinable
  @type add_player_result :: {:ok, :player | :spectator, t()} | {:error, join_error_code()}

  @doc """
  Create a new game based on the supplied options
  """
  @spec new(new_opts()) :: t()
  def new(opts) do
    host_id = Keyword.fetch!(opts, :host_id)
    host_name = Keyword.fetch!(opts, :host_name)
    game_mode = Keyword.fetch!(opts, :game_mode)

    player_names =
      opts
      |> Keyword.get(:players, [])
      |> Enum.reduce(%{}, fn player_name, acc -> Map.put(acc, UUID.generate(), player_name) end)
      |> Map.put(host_id, host_name)

    player_ids = Map.keys(player_names)
    status = if game_mode == :scorekeeper, do: :in_progress, else: :waiting_for_players
    scores = Enum.reduce(player_ids, %{}, fn player, acc -> Map.put(acc, player, %{}) end)

    %__MODULE__{
      game_mode: game_mode,
      game_type: Keyword.fetch!(opts, :game_type),
      allow_spectators: Keyword.get(opts, :allow_spectators, true),
      max_players: Keyword.fetch!(opts, :max_players),
      max_rounds: Keyword.fetch!(opts, :max_rounds),
      host_id: host_id,
      status: status,
      round: 1,
      player_names: player_names,
      scores: scores
    }
  end

  @doc """
  Attempt to add a player to the game
  """
  @spec add_player(t(), String.t(), String.t()) :: add_player_result()
  def add_player(%__MODULE__{player_names: player_names}, player_id, _player_name)
      when is_map(player_names) and is_map_key(player_names, player_id) do
    {:error, :already_exists}
  end

  def add_player(
        %__MODULE__{allow_spectators: false, game_mode: :scorekeeper},
        _player_id,
        _player_name
      ) do
    {:error, :not_joinable}
  end

  def add_player(
        %__MODULE__{allow_spectators: false, game_mode: :party, status: status},
        _player_id,
        _player_name
      )
      when status != :waiting_for_players do
    {:error, :not_joinable}
  end

  def add_player(
        %__MODULE__{allow_spectators: true, game_mode: :scorekeeper} = game,
        _player_id,
        _player_name
      ) do
    {:ok, :spectator, game}
  end

  def add_player(
        %__MODULE__{allow_spectators: true, game_mode: :party, status: status} = game,
        _player_id,
        _player_name
      )
      when status != :waiting_for_players do
    {:ok, :spectator, game}
  end

  def add_player(%__MODULE__{} = game, player_id, player_name) do
    updated_scores = Map.put(game.scores, player_id, %{})
    updated_player_names = Map.put(game.player_names, player_id, player_name)
    updated_game = %{game | scores: updated_scores, player_names: updated_player_names}

    {:ok, :player, updated_game}
  end

  @doc """
  Update the given player's score for the specified round
  """
  @spec update_score(t(), String.t(), pos_integer(), integer()) ::
          {:ok, t()} | {:error, :player_not_found}
  def update_score(%__MODULE__{scores: scores} = game, player_id, round, score) do
    case Map.get(scores, player_id) do
      nil ->
        {:error, :player_not_found}

      player_scores ->
        updated_player_scores = Map.put(player_scores, to_string(round), score)
        updated_scores = Map.put(scores, player_id, updated_player_scores)
        {:ok, %{game | scores: updated_scores}}
    end
  end

  @doc """
  Start the game with the given game ID
  """
  @spec start(t()) :: {:ok, t()} | {:error, start_error_code()}
  def start(%__MODULE__{game_mode: :scorekeeper}) do
    {:error, :invalid_game_mode}
  end

  def start(%__MODULE__{status: status}) when status != :waiting_for_players do
    {:error, :invalid_game_state}
  end

  def start(%__MODULE__{} = game) do
    {:ok, %{game | status: :in_progress}}
  end

  @doc """
  Advance the game to the next round
  """
  @spec advance_round(t()) :: t()
  def advance_round(%__MODULE__{} = game) do
    updated_scores =
      Enum.reduce(game.scores, game.scores, fn {player_id, round_scores}, acc ->
        updated_round_scores = Map.put_new(round_scores, to_string(game.round), 0)
        Map.put(acc, player_id, updated_round_scores)
      end)

    next_round = game.round + 1

    if next_round <= game.max_rounds do
      %{game | scores: updated_scores, round: next_round}
    else
      %{game | scores: updated_scores, status: :complete}
    end
  end

  @doc """
  Decode a JSON string into a game struct
  """
  @spec from_json(String.t()) :: {:ok, t()} | {:error, String.t()}
  def from_json(json) do
    case Jason.decode(json) do
      {:ok, game} ->
        game =
          Enum.reduce(game, %{}, fn
            {key, value}, acc when key in ["status", "game_mode", "game_type"] ->
              Map.put(acc, String.to_existing_atom(key), String.to_existing_atom(value))

            {key, value}, acc ->
              Map.put(acc, String.to_existing_atom(key), value)
          end)

        {:ok, struct(__MODULE__, game)}

      {:error, _reason} ->
        {:error, "Failed to decode game"}
    end
  end
end
