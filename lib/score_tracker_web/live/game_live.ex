defmodule ScoreTrackerWeb.GameLive do
  use ScoreTrackerWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias ScoreTracker.{Game, GameManager, GameType}

  @impl true
  def render(%{is_host: _} = assigns) do
    ~H"""
    <div class="size-full flex flex-col items-center p-4 text-primary bg-background">
      <div class="w-full flex items-center justify-between">
        <h1 class="text-xl font-bold">{GameType.friendly_name(@game.game_type)}</h1>
        <div
          class="flex items-center gap-2"
          phx-hook="CopyToClipboard"
          id="game-id-wrapper"
          data-copy-text={@game_id}
        >
          <span>Game ID:</span>
          <span class="font-bold">{@game_id}</span>
          <button
            type="button"
            aria-label="Copy to clipboard"
            class="cursor-pointer hover:text-primary/80"
          >
            <.icon name="hero-clipboard-document" class="size-5" />
          </button>
        </div>
      </div>
      <div class="w-full my-4 grid grid-cols-2 md:grid-cols-4 gap-4">
        <.stat_card label="Round" value={@game.round} />
        <.stat_card label="Status" value={Game.get_status(@game.status)} />
        <.stat_card label="Max Players" value={@game.max_players} />
        <.stat_card label="Max Rounds" value={@game.max_rounds} />
      </div>
      <div class="w-full">
        <div class="flex items-center justify-between mb-2">
          <h2 class="text-lg font-bold">Scoreboard</h2>
          <.button
            :if={Game.host?(@game, @user_id) and @game.status == :waiting_for_players}
            type="button"
            phx-click="start_game"
          >
            Start Game
          </.button>
          <.button
            :if={Game.host?(@game, @user_id) and Game.in_progress?(@game)}
            type="button"
            phx-click={JS.show(to: "#go-to-next-round")}
          >
            {if @game.round < @game.max_rounds, do: "Next Round", else: "End Game"}
          </.button>
          <.modal
            id="go-to-next-round"
            on_cancel={JS.hide(to: "#go-to-next-round")}
          >
            <div class="text-primary">
              <h2 class="text-xl font-bold mb-4">
                {if @game.round < @game.max_rounds,
                  do: "Go to Round #{@game.round + 1}",
                  else: "End Game"}?
              </h2>
              <p>
                {if Game.any_missing_player_round_score?(@game),
                  do:
                    Enum.join(
                      [
                        "There are players without a score for the current round.",
                        "Are you sure you want to progress without updating their scores?"
                      ],
                      " "
                    ),
                  else: "Are you sure you want to progress to the next round?"}
              </p>
              <div class="flex justify-between mt-5">
                <.button
                  type="button"
                  class="bg-secondary text-secondary-foreground hover:bg-secondary/80"
                  phx-click={JS.hide(to: "#go-to-next-round")}
                >
                  Cancel
                </.button>
                <.button
                  type="button"
                  phx-click={JS.hide(to: "#go-to-next-round") |> JS.push("next_round")}
                >
                  Continue
                </.button>
              </div>
            </div>
          </.modal>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full table-auto border-collapse text-center">
            <thead class="bg-background text-primary">
              <tr>
                <th></th>
                <th class="p-3">Player</th>
                <th :for={round <- 1..@game.max_rounds} class="p-3">{round}</th>
                <th class="p-3">Total</th>
              </tr>
            </thead>
            <tbody class="border border-border">
              <tr
                :for={{player_id, player_name} <- @game.player_names}
                class="hover:bg-primary hover:text-primary-foreground"
              >
                <td>
                  <button
                    :if={Game.user_score_editable?(@game, player_id, @user_id)}
                    type="button"
                    class="flex items-center justify-center gap-1 px-4 hover:cursor-pointer"
                    phx-click={JS.show(to: "#edit-#{player_id}-score")}
                  >
                    <span class="hero-pencil-square-mini"></span>
                  </button>
                  <.modal
                    id={"edit-#{player_id}-score"}
                    on_cancel={JS.hide(to: "#edit-#{player_id}-score")}
                  >
                    <div>
                      <h2 class="text-xl font-bold mb-4 text-primary">
                        Edit {player_name}'s Round {@game.round} Score
                      </h2>
                      <.live_component
                        id={"edit-#{player_id}-score-form"}
                        module={ScoreTrackerWeb.UpdateScoreForm}
                        game_id={@game_id}
                        player_id={player_id}
                        game_type={@game.game_type}
                        round={@game.round}
                        on_cancel={JS.hide(to: "#edit-#{player_id}-score")}
                      />
                    </div>
                  </.modal>
                </td>
                <td class="p-3 font-medium">{player_name}</td>
                <td :for={round <- 1..@game.max_rounds} class="p-3">
                  {Map.get(@game.scores[player_id], to_string(round), "-")}
                </td>
                <td class="p-3 font-bold">
                  {Game.player_total_score(player_id, @game)}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp stat_card(%{label: _, value: _} = assigns) do
    ~H"""
    <div class="bg-card p-4 rounded-lg border border-border text-card-foreground text-center">
      <p class="text-sm">{@label}</p>
      <p class="text-2xl font-bold">{@value}</p>
    </div>
    """
  end

  @impl true
  def mount(%{"game_id" => game_id}, session, socket) do
    case Game.get(game_id) do
      {:ok, game} ->
        user_id = session["user_id"]
        is_host = Game.host?(game, user_id)

        if connected?(socket) do
          Phoenix.PubSub.subscribe(ScoreTracker.PubSub, Game.topic(game_id))
        end

        send(self(), :after_mount)

        socket =
          assign(socket, %{
            user_id: user_id,
            game_id: game_id,
            game: game,
            is_host: is_host
          })

        {:ok, socket}

      {:error, :not_found} ->
        {:ok, push_navigate(socket, to: ~p"/")}
    end
  end

  @impl true
  def terminate(_reason, %Socket{assigns: %{game_id: game_id}}) do
    Phoenix.PubSub.unsubscribe(ScoreTracker.PubSub, Game.topic(game_id))
  end

  @impl true
  def handle_event("start_game", _params, %Socket{assigns: %{game_id: game_id}} = socket) do
    {:ok, status} = GameManager.start_game(GameManager, game_id: game_id)
    ScoreTrackerWeb.Endpoint.broadcast(Game.topic(game_id), "start_game", %{status: status})
    {:noreply, socket}
  end

  @impl true
  def handle_event("next_round", _params, %Socket{assigns: %{game_id: game_id}} = socket) do
    {:ok, _} = GameManager.advance_to_next_round(GameManager, game_id: game_id)
    ScoreTrackerWeb.Endpoint.broadcast(Game.topic(game_id), "next_round", %{})
    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_mount, %Socket{assigns: %{game_id: game_id}} = socket) do
    ScoreTrackerWeb.Endpoint.broadcast_from(self(), Game.topic(game_id), "joined", %{})
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "start_game", payload: %{status: status}}, socket) do
    {:noreply, update(socket, :game, &Map.put(&1, :status, status))}
  end

  @impl true
  def handle_info(%{event: event}, %Socket{assigns: %{game_id: game_id}} = socket)
      when event in ["joined", "next_round"] do
    {:ok, game} = Game.get(game_id)
    {:noreply, assign(socket, game: game)}
  end
end
