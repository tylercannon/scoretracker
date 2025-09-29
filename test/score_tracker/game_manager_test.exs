defmodule ScoreTracker.GameManagerTest do
  use ExUnit.Case, async: true

  alias NimbleOptions.ValidationError
  alias ScoreTracker.{GameManager, GameStorage}
  alias ScoreTracker.GameType.{Ripple, Rummy}

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
        players: ["PlayerTwo", "PlayerThree"]
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
      assert "PlayerTwo" in player_names
      assert "PlayerThree" in player_names
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
        game_type: :rummy,
        max_players: Rummy.max_players(),
        max_rounds: Rummy.max_rounds()
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
    setup do
      party_game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :ripple,
        max_players: Ripple.max_players(),
        max_rounds: Ripple.max_rounds()
      ]

      scorekeeper_game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 5,
        players: ["PlayerTwo", "PlayerThree"]
      ]

      %{party_game_opts: party_game_opts, scorekeeper_game_opts: scorekeeper_game_opts}
    end

    test "adds a player to a party game", %{
      game_manager: game_manager,
      party_game_opts: game_opts
    } do
      game_id = GameManager.create_game(game_manager, game_opts)

      player_opts = [game_id: game_id, player_id: "player1", player_name: "PlayerOne"]
      :ok = GameManager.add_player(game_manager, player_opts)

      {:ok, game} = GameManager.get_game(game_manager, game_id)
      assert game.player_names["player1"] == "PlayerOne"
      assert game.scores["player1"] == %{}
    end

    test "adds a spectator to a scorekeeper game", %{
      game_manager: game_manager,
      scorekeeper_game_opts: game_opts
    } do
      game_id = GameManager.create_game(game_manager, game_opts)

      player_id = "player1"
      player_opts = [game_id: game_id, player_id: player_id, player_name: "PlayerOne"]
      :ok = GameManager.add_player(game_manager, player_opts)

      {:ok, game} = GameManager.get_game(game_manager, game_id)
      refute player_id in game.player_names
    end

    test "adds a spectator to a party game", %{
      game_manager: game_manager,
      party_game_opts: game_opts
    } do
      # create and start a game to put it into the correct state
      game_id = GameManager.create_game(game_manager, game_opts)
      {:ok, :in_progress} = GameManager.start_game(game_manager, game_id: game_id)

      player_id = "player1"
      player_opts = [game_id: game_id, player_id: player_id, player_name: "PlayerOne"]
      :ok = GameManager.add_player(game_manager, player_opts)

      {:ok, game} = GameManager.get_game(game_manager, game_id)
      refute player_id in game.player_names
    end

    test "rejects player that already exists in a party game", %{
      game_manager: game_manager,
      party_game_opts: game_opts
    } do
      game_id = GameManager.create_game(game_manager, game_opts)

      player_opts = [game_id: game_id, player_id: "player1", player_name: "PlayerOne"]
      # add the player once so it exists in the game state
      :ok = GameManager.add_player(game_manager, player_opts)

      assert {:error, :already_exists} == GameManager.add_player(game_manager, player_opts)
    end

    test "rejects adding spectator to a scorekeeper game", %{
      game_manager: game_manager,
      scorekeeper_game_opts: game_opts
    } do
      game_opts = Keyword.put(game_opts, :allow_spectators, false)
      game_id = GameManager.create_game(game_manager, game_opts)

      player_opts = [game_id: game_id, player_id: "player4", player_name: "PlayerFour"]
      assert {:error, :not_joinable} == GameManager.add_player(game_manager, player_opts)
    end

    test "rejects adding spectator to a party game", %{
      game_manager: game_manager,
      party_game_opts: game_opts
    } do
      game_opts = Keyword.put(game_opts, :allow_spectators, false)

      # create and start a game to put it into the correct state
      game_id = GameManager.create_game(game_manager, game_opts)
      {:ok, :in_progress} = GameManager.start_game(game_manager, game_id: game_id)

      player_opts = [game_id: game_id, player_id: "player4", player_name: "PlayerFour"]
      assert {:error, :not_joinable} == GameManager.add_player(game_manager, player_opts)
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
