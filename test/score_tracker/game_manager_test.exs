defmodule ScoreTracker.GameManagerTest do
  use ExUnit.Case, async: true

  alias NimbleOptions.ValidationError
  alias ScoreTracker.{GameManager, GameStorage}
  alias ScoreTracker.GameType.Ripple

  setup context do
    opts = [
      name: context.test,
      storage_backend: GameStorage.Ets,
      storage_backend_opts: [:named_table]
    ]

    _ = start_supervised!({GameManager, opts})

    %{game_manager: context.test}
  end

  describe "create_game/1" do
    test "scorekeeper game with valid options", %{game_manager: game_manager} do
      game_opts = [
        allow_spectators: false,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 5,
        players: ["Player 2", "Player 3"]
      ]

      game_id = GameManager.create_game(game_manager, game_opts)
      assert is_binary(game_id)

      {:ok, game} = GameManager.get_game(game_manager, game_id)

      assert game.game_mode == :scorekeeper
      assert game.game_type == :custom
      assert game.allow_spectators == false
      assert game.max_players == 4
      assert game.max_rounds == 5
      assert game.host_id == "game-host"
      assert game.status == :in_progress
      assert game.round == 1

      player_names = Map.values(game.player_names)
      assert Enum.count(player_names) == 3
      assert "Player 2" in player_names
      assert "Player 3" in player_names
      assert "Example" in player_names

      scores = Map.values(game.scores)
      assert Enum.count(scores) == 3
    end

    test "party game with valid options", %{game_manager: game_manager} do
      game_opts = [
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :ripple,
        max_players: Ripple.max_players(),
        max_rounds: Ripple.max_rounds()
      ]

      game_id = GameManager.create_game(game_manager, game_opts)
      assert is_binary(game_id)

      {:ok, game} = GameManager.get_game(game_manager, game_id)

      assert game == %{
               game_mode: :party,
               game_type: :ripple,
               allow_spectators: true,
               max_players: 6,
               max_rounds: 10,
               host_id: "game-host",
               status: :waiting_for_players,
               round: 1,
               player_names: %{"game-host" => "Example"},
               scores: %{"game-host" => %{}}
             }
    end

    test "validation error for empty options", %{game_manager: game_manager} do
      assert {:error,
              %ValidationError{
                key: :host_id,
                keys_path: [],
                message: "required :host_id option not found, received options: []",
                value: nil
              }} == GameManager.create_game(game_manager, [])
    end

    test "validation error for invalid options", %{game_manager: game_manager} do
      invalid_game_opts = [
        host_id: true,
        host_name: false,
        game_mode: 1,
        game_type: 2,
        allow_spectators: 0,
        max_players: "ten",
        max_rounds: "four"
      ]

      valid_game_opts = [
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :ripple,
        max_players: Ripple.max_players(),
        max_rounds: Ripple.max_rounds()
      ]

      Enum.each(invalid_game_opts, fn {key, value} ->
        game_opts = Keyword.put(valid_game_opts, key, value)

        {:error, validation_error} = GameManager.create_game(game_manager, game_opts)
        assert validation_error.key == key
        assert validation_error.message =~ "invalid value for :#{key} option"
        assert validation_error.value == value
      end)
    end
  end

  describe "add_player/1" do
    test "adds a player to a party game", %{game_manager: game_manager} do
      game_opts = [
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :ripple,
        max_players: Ripple.max_players(),
        max_rounds: Ripple.max_rounds()
      ]

      game_id = GameManager.create_game(game_manager, game_opts)

      player_opts = [game_id: game_id, player_id: "player1", player_name: "Player One"]
      :ok = GameManager.add_player(game_manager, player_opts)

      {:ok, game} = GameManager.get_game(game_manager, game_id)
      assert game.player_names["player1"] == "Player One"
      assert game.scores["player1"] == %{}
    end
  end

  describe "update_player_score/1" do
  end

  describe "start_game/1" do
  end

  describe "advance_to_next_round/1" do
  end

  describe "get_game/1" do
  end
end
