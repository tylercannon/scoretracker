defmodule ScoreTrackerWeb.GameLiveTest do
  use ScoreTrackerWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScoreTracker.GameServer
  alias ScoreTracker.GameType.Ripple

  setup do
    start_supervised!({Agent, fn -> :ets.new(:lobbies, [:named_table, :public, :set]) end})

    on_exit(fn ->
      ScoreTracker.GameSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_, pid, _, _} ->
        DynamicSupervisor.terminate_child(ScoreTracker.GameSupervisor, pid)
      end)
    end)

    :ok
  end

  describe "access control - scorekeeper" do
    setup do
      game_opts = [
        allow_spectators: false,
        game_mode: :scorekeeper,
        game_type: :custom,
        host_id: "host-id",
        host_name: "Example",
        max_players: 4,
        max_rounds: 5,
        players: ["PlayerTwo", "PlayerThree"],
        winning_score_type: :highest
      ]

      %{game_opts: game_opts}
    end

    test "host can access game when spectating is disabled", %{conn: conn, game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      conn = Plug.Test.init_test_session(conn, %{user_id: game_opts[:host_id]})

      {:ok, _view, html} = live(conn, ~p"/game/#{game_id}")
      assert html =~ "Scoreboard"
    end

    test "host can access game when spectating is enabled", %{conn: conn, game_opts: game_opts} do
      game_id =
        game_opts
        |> Keyword.put(:allow_spectators, true)
        |> GameServer.create_game()

      conn = Plug.Test.init_test_session(conn, %{user_id: game_opts[:host_id]})

      {:ok, _view, html} = live(conn, ~p"/game/#{game_id}")
      assert html =~ "Scoreboard"
    end

    test "anon is redirected when spectating is disabled", %{conn: conn, game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      conn = Plug.Test.init_test_session(conn, %{user_id: "random-id"})

      assert {:error, {:live_redirect, %{to: "/", flash: %{}}}} = live(conn, ~p"/game/#{game_id}")
    end

    test "anon can spectate when spectating is enabled", %{conn: conn, game_opts: game_opts} do
      game_id =
        game_opts
        |> Keyword.put(:allow_spectators, true)
        |> GameServer.create_game()

      conn = Plug.Test.init_test_session(conn, %{user_id: "random-id"})

      {:ok, _view, html} = live(conn, ~p"/game/#{game_id}")
      assert html =~ "Scoreboard"
    end
  end

  describe "access control - party - not started" do
    setup do
      game_opts = [
        allow_spectators: false,
        game_mode: :party,
        game_type: :ripple,
        host_id: "host-id",
        host_name: "Host",
        max_players: Ripple.max_players(),
        max_rounds: Ripple.max_rounds(),
        winning_score_type: Ripple.winning_score_type()
      ]

      %{game_opts: game_opts}
    end

    test "host can access game when spectating is disabled", %{conn: conn, game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      conn = Plug.Test.init_test_session(conn, %{user_id: game_opts[:host_id]})

      {:ok, _view, html} = live(conn, ~p"/game/#{game_id}")
      assert html =~ "Scoreboard"
    end

    test "host can access game when spectating is enabled", %{conn: conn, game_opts: game_opts} do
      game_id =
        game_opts
        |> Keyword.put(:allow_spectators, true)
        |> GameServer.create_game()

      conn = Plug.Test.init_test_session(conn, %{user_id: game_opts[:host_id]})

      {:ok, _view, html} = live(conn, ~p"/game/#{game_id}")
      assert html =~ "Scoreboard"
    end

    test "player can access game when spectating is disabled", %{conn: conn, game_opts: game_opts} do
      player_id = "player-id"
      game_id = GameServer.create_game(game_opts)

      :ok = GameServer.add_player(game_id: game_id, player_id: player_id, player_name: "Player")

      conn = Plug.Test.init_test_session(conn, %{user_id: player_id})

      {:ok, _view, html} = live(conn, ~p"/game/#{game_id}")
      assert html =~ "Scoreboard"
    end

    test "player can access game when spectating is enabled", %{conn: conn, game_opts: game_opts} do
      player_id = "player-id"

      game_id =
        game_opts
        |> Keyword.put(:allow_spectators, true)
        |> GameServer.create_game()

      :ok = GameServer.add_player(game_id: game_id, player_id: player_id, player_name: "Player")

      conn = Plug.Test.init_test_session(conn, %{user_id: player_id})

      {:ok, _view, html} = live(conn, ~p"/game/#{game_id}")
      assert html =~ "Scoreboard"
    end

    test "anon is redirected when spectating is disabled", %{conn: conn, game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      conn = Plug.Test.init_test_session(conn, %{user_id: "random-id"})

      assert {:error, {:live_redirect, %{to: "/", flash: %{}}}} = live(conn, ~p"/game/#{game_id}")
    end

    test "anon is redirected when spectating is enabled", %{conn: conn, game_opts: game_opts} do
      game_id =
        game_opts
        |> Keyword.put(:allow_spectators, true)
        |> GameServer.create_game()

      conn = Plug.Test.init_test_session(conn, %{user_id: "random-id"})

      assert {:error, {:live_redirect, %{to: "/", flash: %{}}}} = live(conn, ~p"/game/#{game_id}")
    end
  end

  describe "access control - party - in progress" do
    setup do
      game_opts = [
        allow_spectators: false,
        game_mode: :party,
        game_type: :ripple,
        host_id: "host-id",
        host_name: "Host",
        max_players: Ripple.max_players(),
        max_rounds: Ripple.max_rounds(),
        winning_score_type: Ripple.winning_score_type()
      ]

      %{game_opts: game_opts}
    end

    test "host can access game when spectating is disabled", %{conn: conn, game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      {:ok, :in_progress} = GameServer.start_game(game_id)

      conn = Plug.Test.init_test_session(conn, %{user_id: game_opts[:host_id]})

      {:ok, _view, html} = live(conn, ~p"/game/#{game_id}")
      assert html =~ "Scoreboard"
    end

    test "host can access game when spectating is enabled", %{conn: conn, game_opts: game_opts} do
      game_id =
        game_opts
        |> Keyword.put(:allow_spectators, true)
        |> GameServer.create_game()

      {:ok, :in_progress} = GameServer.start_game(game_id)

      conn = Plug.Test.init_test_session(conn, %{user_id: game_opts[:host_id]})

      {:ok, _view, html} = live(conn, ~p"/game/#{game_id}")
      assert html =~ "Scoreboard"
    end

    test "player can access game when spectating is disabled", %{conn: conn, game_opts: game_opts} do
      player_id = "player-id"
      game_id = GameServer.create_game(game_opts)

      :ok = GameServer.add_player(game_id: game_id, player_id: player_id, player_name: "Player")
      {:ok, :in_progress} = GameServer.start_game(game_id)

      conn = Plug.Test.init_test_session(conn, %{user_id: player_id})

      {:ok, _view, html} = live(conn, ~p"/game/#{game_id}")
      assert html =~ "Scoreboard"
    end

    test "player can access game when spectating is enabled", %{conn: conn, game_opts: game_opts} do
      player_id = "player-id"

      game_id =
        game_opts
        |> Keyword.put(:allow_spectators, true)
        |> GameServer.create_game()

      :ok = GameServer.add_player(game_id: game_id, player_id: player_id, player_name: "Player")
      {:ok, :in_progress} = GameServer.start_game(game_id)

      conn = Plug.Test.init_test_session(conn, %{user_id: player_id})

      {:ok, _view, html} = live(conn, ~p"/game/#{game_id}")
      assert html =~ "Scoreboard"
    end

    test "anon is redirected when spectating is disabled", %{conn: conn, game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      {:ok, :in_progress} = GameServer.start_game(game_id)

      conn = Plug.Test.init_test_session(conn, %{user_id: "random-id"})

      assert {:error, {:live_redirect, %{to: "/", flash: %{}}}} = live(conn, ~p"/game/#{game_id}")
    end

    test "anon can spectate when spectating is enabled", %{conn: conn, game_opts: game_opts} do
      game_id =
        game_opts
        |> Keyword.put(:allow_spectators, true)
        |> GameServer.create_game()

      {:ok, :in_progress} = GameServer.start_game(game_id)

      conn = Plug.Test.init_test_session(conn, %{user_id: "random-id"})

      {:ok, _view, html} = live(conn, ~p"/game/#{game_id}")
      assert html =~ "Scoreboard"
    end
  end

  describe "access control - non-existent game" do
    test "user is redirected", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{user_id: "random-id"})

      assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/game/invalid-game-id")
    end
  end
end
