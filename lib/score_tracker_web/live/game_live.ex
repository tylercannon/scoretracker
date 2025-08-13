defmodule ScoreTrackerWeb.GameLive do
  use ScoreTrackerWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias ScoreTracker.Game

  @impl true
  def render(%{is_host: _} = assigns) do
    ~H"""
    <div class="w-full flex flex-col items-center justify-center p-4 text-slate-800">
      <div class="w-full flex items-center justify-between">
        <h1 class="text-xl font-bold">Game Details</h1>
        <div class="flex gap-2">
          <span>Game ID:</span>
          <span class="font-bold">{@game_id}</span>
        </div>
      </div>
      <div class="w-full my-4 grid grid-cols-2 md:grid-cols-4 gap-4">
        <.stat_card label="Round" value={@game.round} />
        <.stat_card label="Status" value={Game.get_status(@game.status)} />
        <.stat_card label="Max Players" value={@game.max_players} />
        <.stat_card label="Max Rounds" value={@game.max_rounds} />
      </div>
      <div class="w-full">
        <h2 class="text-lg font-bold mb-2">Scoreboard</h2>
        <div class="overflow-x-auto">
          <table class="w-full table-auto border-collapse text-center">
            <thead class="bg-slate-800 text-white">
              <tr>
                <th></th>
                <th class="p-3">Player</th>
                <th :for={round <- 1..@game.max_rounds} class="p-3">{round}</th>
                <th class="p-3">Total</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-800">
              <tr
                :for={{player_id, player_name} <- @game.player_names}
                class="hover:bg-slate-800 hover:text-white"
              >
                <td>
                  <button
                    :if={@is_host}
                    type="button"
                    class="flex items-center justify-center gap-1 px-4"
                    phx-click={JS.show(to: "#edit-#{player_id}-score")}
                  >
                    <span class="hero-pencil-square-mini"></span>
                  </button>
                  <.modal
                    id={"edit-#{player_id}-score"}
                    on_cancel={JS.hide(to: "#edit-#{player_id}-score")}
                  >
                    <div>
                      <h2 class="text-xl font-bold mb-4 text-white">
                        Edit {player_name}'s Round {@game.round} Score
                      </h2>
                      <.live_component
                        id={"edit-#{player_id}-score-form"}
                        module={ScoreTrackerWeb.UpdateScoreForm}
                        player_id={player_id}
                        game_id={@game_id}
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
    <div class="bg-slate-800 p-4 rounded-lg text-white text-center">
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
        is_host = game.host_id == user_id

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
  def handle_info(:after_mount, %Socket{assigns: %{game_id: game_id}} = socket) do
    ScoreTrackerWeb.Endpoint.broadcast_from(self(), Game.topic(game_id), "joined", %{})
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "joined"}, %Socket{assigns: %{game_id: game_id}} = socket) do
    {:ok, game} = Game.get(game_id)
    {:noreply, assign(socket, game: game)}
  end
end
