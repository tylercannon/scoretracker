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
               game_type: :rummy,
               allow_spectators: true,
               max_players: 8,
               max_rounds: 8,
               players: [],
               winning_score_type: :lowest
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
                players: [],
                winning_score_type: Ripple.winning_score_type()
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
                players: [],
                winning_score_type: Rummy.winning_score_type()
              }} == Ecto.Changeset.apply_action(changeset, :update)
    end

    test "valid custom params" do
      params = %{
        "host_name" => "Example",
        "game_mode" => "scorekeeper",
        "game_type" => "custom",
        "allow_spectators" => false,
        "max_players" => 3,
        "max_rounds" => 5,
        "custom_name" => "My Game",
        "players" => %{
          "0" => %{"name" => "PlayerTwo"},
          "1" => %{"name" => "PlayerThree"}
        },
        "winning_score_type" => "highest"
      }

      changeset = CreateGame.changeset(%CreateGame{}, params)

      assert changeset.valid?

      assert {:ok,
              %CreateGame{
                host_name: "Example",
                game_mode: :scorekeeper,
                game_type: :custom,
                allow_spectators: false,
                max_players: 3,
                max_rounds: 5,
                custom_name: "My Game",
                players: [
                  %Player{name: "PlayerTwo"},
                  %Player{name: "PlayerThree"}
                ],
                winning_score_type: :highest
              }} == Ecto.Changeset.apply_action(changeset, :update)
    end

    test "empty params" do
      changeset = CreateGame.changeset(%CreateGame{}, %{})

      refute changeset.valid?

      assert %{host_name: ["can't be blank"]} == ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid params" do
      params = %{
        "custom_name" => "Invalid!",
        "host_name" => "Invalid1",
        "game_mode" => "unknown",
        "game_type" => "invalid",
        "allow_spectators" => "yes",
        "max_players" => 1,
        "max_rounds" => 100,
        "players" => %{
          "0" => %{"name" => "Player2"},
          "1" => %{"name" => "PlayerThree"}
        },
        "winning_score_type" => "invalid"
      }

      {:error, changeset} =
        %CreateGame{}
        |> CreateGame.changeset(params)
        |> Ecto.Changeset.apply_action(:update)

      assert %{
               host_name: ["must be valid format"],
               game_mode: ["must be one of: party | scorekeeper"],
               game_type: ["must be one of: custom | five_crowns | ripple | rummy"],
               allow_spectators: ["must be of type: boolean"],
               max_players: ["must be greater than or equal to 2"],
               max_rounds: ["must be less than or equal to 20"],
               players: [
                 %{name: ["must be valid format"]},
                 %{name: ["must not exceed max player count"]}
               ],
               winning_score_type: ["must be one of: highest | lowest"]
             } == ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid params for custom game" do
      params = %{
        "custom_name" => "MyInvalidGameName!",
        "host_name" => "Invalid1",
        "game_mode" => "unknown",
        "game_type" => "custom",
        "allow_spectators" => "yes",
        "max_players" => 1,
        "max_rounds" => 100,
        "players" => %{
          "0" => %{"name" => "Player2"},
          "1" => %{"name" => "PlayerThree"}
        },
        "winning_score_type" => "invalid"
      }

      {:error, changeset} =
        %CreateGame{}
        |> CreateGame.changeset(params)
        |> Ecto.Changeset.apply_action(:update)

      assert %{
               custom_name: ["must be valid format", "should be at most 12 character(s)"],
               host_name: ["must be valid format"],
               game_mode: ["must be one of: party | scorekeeper"],
               allow_spectators: ["must be of type: boolean"],
               max_players: ["must be greater than or equal to 2"],
               max_rounds: ["must be less than or equal to 20"],
               players: [
                 %{name: ["must be valid format"]},
                 %{name: ["must not exceed max player count"]}
               ],
               winning_score_type: ["must be one of: highest | lowest"]
             } == ScoreTracker.Changeset.format_errors(changeset)
    end

    test "duplicate player names" do
      params = %{
        "host_name" => "Example",
        "game_mode" => "scorekeeper",
        "game_type" => "custom",
        "max_players" => 4,
        "max_rounds" => 5,
        "players" => %{
          "0" => %{"name" => "PlayerTwo"},
          "1" => %{"name" => "PlayerThree"},
          "2" => %{"name" => "PlayerTwo"}
        }
      }

      changeset = CreateGame.changeset(%CreateGame{}, params)

      refute changeset.valid?

      assert %{players: [%{}, %{}, %{name: ["must be unique"]}]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end

    test "host name conflicts with player name" do
      params = %{
        "host_name" => "Example",
        "game_mode" => "scorekeeper",
        "game_type" => "custom",
        "max_players" => 4,
        "max_rounds" => 5,
        "players" => %{
          "0" => %{"name" => "PlayerTwo"},
          "1" => %{"name" => "Example"}
        }
      }

      changeset = CreateGame.changeset(%CreateGame{}, params)

      refute changeset.valid?

      assert %{players: [%{}, %{name: ["must be unique"]}]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end

    test "duplicate player names with no host name" do
      params = %{
        "game_mode" => "scorekeeper",
        "game_type" => "custom",
        "max_players" => 4,
        "max_rounds" => 5,
        "players" => %{
          "0" => %{"name" => "PlayerTwo"},
          "1" => %{"name" => "PlayerTwo"}
        }
      }

      changeset = CreateGame.changeset(%CreateGame{}, params)

      refute changeset.valid?

      assert %{
               host_name: ["can't be blank"],
               players: [%{}, %{name: ["must be unique"]}]
             } == ScoreTracker.Changeset.format_errors(changeset)
    end

    test "exceeds max players" do
      params = %{
        "host_name" => "Example",
        "game_mode" => "scorekeeper",
        "game_type" => "custom",
        "max_players" => 3,
        "max_rounds" => 5,
        "players" => %{
          "0" => %{"name" => "PlayerTwo"},
          "1" => %{"name" => "PlayerThree"},
          "2" => %{"name" => "PlayerFour"}
        }
      }

      changeset = CreateGame.changeset(%CreateGame{}, params)

      refute changeset.valid?

      assert %{
               players: [%{}, %{}, %{name: ["must not exceed max player count"]}]
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
                players: [],
                winning_score_type: Ripple.winning_score_type()
              }} == CreateGame.update(%CreateGame{}, params)
    end

    test "invalid params" do
      params = %{
        "host_name" => "Example",
        "game_mode" => "party",
        "game_type" => "ripple",
        "max_players" => 11,
        "max_rounds" => 0,
        "winning_score_type" => "invalid"
      }

      {:error, changeset} = CreateGame.update(%CreateGame{}, params)

      assert %{
               max_players: ["must be less than or equal to 10"],
               max_rounds: ["must be greater than or equal to 1"],
               winning_score_type: ["must be one of: highest | lowest"]
             } == ScoreTracker.Changeset.format_errors(changeset)
    end
  end
end
