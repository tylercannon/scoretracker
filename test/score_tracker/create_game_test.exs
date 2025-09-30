defmodule ScoreTracker.CreateGameTest do
  use ExUnit.Case, async: true

  alias ScoreTracker.CreateGame
  alias ScoreTracker.GameType.{Ripple, Rummy}
  alias ScoreTracker.Player

  describe "defaults" do
    test "values match expected values" do
      create_game = %CreateGame{}

      assert %CreateGame{
               host_name: nil,
               game_mode: :scorekeeper,
               game_type: :custom,
               allow_spectators: true,
               max_players: 6,
               max_rounds: 10,
               players: []
             } == create_game
    end
  end

  describe "changeset/2" do
    test "valid ripple params" do
      params = %{"host_name" => "Example", "game_mode" => "party", "game_type" => "ripple"}
      changeset = CreateGame.changeset(%CreateGame{}, params)

      assert changeset.valid?

      assert {:ok,
              %CreateGame{
                host_name: "Example",
                game_mode: :party,
                game_type: :ripple,
                allow_spectators: true,
                max_players: Ripple.max_players(),
                max_rounds: Ripple.max_rounds(),
                players: []
              }} == Ecto.Changeset.apply_action(changeset, :update)
    end

    test "valid rummy params" do
      params = %{"host_name" => "Example", "game_mode" => "party", "game_type" => "rummy"}
      changeset = CreateGame.changeset(%CreateGame{}, params)

      assert changeset.valid?

      assert {:ok,
              %CreateGame{
                host_name: "Example",
                game_mode: :party,
                game_type: :rummy,
                allow_spectators: true,
                max_players: Rummy.max_players(),
                max_rounds: Rummy.max_rounds(),
                players: []
              }} == Ecto.Changeset.apply_action(changeset, :update)
    end

    test "valid custom params" do
      params = %{
        "host_name" => "Example",
        "game_mode" => "scorekeeper",
        "game_type" => "custom",
        "allow_spectators" => false,
        "max_players" => 4,
        "max_rounds" => 5,
        "players" => %{
          "0" => %{"name" => "PlayerTwo"},
          "1" => %{"name" => "PlayerThree"}
        }
      }

      changeset = CreateGame.changeset(%CreateGame{}, params)

      assert changeset.valid?

      assert {:ok,
              %CreateGame{
                host_name: "Example",
                game_mode: :scorekeeper,
                game_type: :custom,
                allow_spectators: false,
                max_players: 4,
                max_rounds: 5,
                players: [
                  %Player{name: "PlayerTwo"},
                  %Player{name: "PlayerThree"}
                ]
              }} == Ecto.Changeset.apply_action(changeset, :update)
    end

    test "empty params" do
      changeset = CreateGame.changeset(%CreateGame{}, %{})

      refute changeset.valid?

      assert %{host_name: ["can't be blank"]} == ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid params" do
      params = %{
        "host_name" => "Invalid1",
        "game_mode" => "unknown",
        "game_type" => "invalid",
        "allow_spectators" => "yes",
        "max_players" => 1,
        "max_rounds" => 100,
        "players" => %{
          "0" => %{"name" => "Player2"},
          "1" => %{"name" => "PlayerThree"}
        }
      }

      {:error, changeset} =
        %CreateGame{}
        |> CreateGame.changeset(params)
        |> Ecto.Changeset.apply_action(:update)

      assert %{
               host_name: ["must be valid format"],
               game_mode: ["must be one of: party | scorekeeper"],
               game_type: ["must be one of: custom | ripple | rummy"],
               allow_spectators: ["must be of type: boolean"],
               max_players: ["must be greater than or equal to 2"],
               max_rounds: ["must be less than or equal to 20"],
               players: [%{name: ["must be valid format"]}, %{}]
             } == ScoreTracker.Changeset.format_errors(changeset)
    end
  end

  describe "update/2" do
    test "valid params" do
      params = %{
        "host_name" => "Example",
        "game_mode" => "party",
        "game_type" => "ripple"
      }

      assert {:ok,
              %CreateGame{
                host_name: "Example",
                game_mode: :party,
                game_type: :ripple,
                allow_spectators: true,
                max_players: Ripple.max_players(),
                max_rounds: Ripple.max_rounds(),
                players: []
              }} == CreateGame.update(%CreateGame{}, params)
    end

    test "invalid params" do
      params = %{
        "host_name" => "Example",
        "game_mode" => "party",
        "game_type" => "ripple",
        "max_players" => 11,
        "max_rounds" => 0
      }

      {:error, changeset} = CreateGame.update(%CreateGame{}, params)

      assert %{
               max_players: ["must be less than or equal to 10"],
               max_rounds: ["must be greater than or equal to 1"]
             } == ScoreTracker.Changeset.format_errors(changeset)
    end
  end
end
