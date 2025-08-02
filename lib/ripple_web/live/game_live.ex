defmodule RippleWeb.GameLive do
  use RippleWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Ripple.Game

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full flex flex-col items-center justify-center p-4">
      <h1 class="text-xl font-bold mb-4">Game Details</h1>
      <div class="flex flex-col gap-2">
        <span>Is Host: {@is_host}</span>
        <span>Round: {@game.round}</span>
        <span>Status: {@game.status}</span>
        <span>Max Players: {@game.max_players}</span>
        <span>Max Rounds: {@game.max_rounds}</span>
      </div>
      <table>
        <thead class="border-b border-gray-500">
          <tr>
            <th class="p-2">Player</th>
            <th class="p-2">Score</th>
          </tr>
        </thead>
        <tbody>
          <%= for {player_id, player_name} <- @game.player_names do %>
            <tr>
              <td class="border-r border-gray-500 p-2">{player_name}</td>
              <td class="text-center p-2">{Game.player_total_score(player_id, @game)}</td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  @impl true
  def mount(%{"game_id" => game_id}, session, socket) do
    # todo: handle invalid game ids
    {:ok, game} = Game.get(game_id)
    user_id = session["user_id"]
    is_host = game.host_id == user_id

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Ripple.PubSub, Game.topic(game_id))
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
  end

  @impl true
  def terminate(_reason, %Socket{assigns: %{game_id: game_id}}) do
    Phoenix.PubSub.unsubscribe(Ripple.PubSub, Game.topic(game_id))
  end

  @impl true
  def handle_info(:after_mount, %Socket{assigns: %{game_id: game_id}} = socket) do
    RippleWeb.Endpoint.broadcast_from(self(), Game.topic(game_id), "joined", %{})
    {:noreply, socket}
  end

  def handle_info(%{event: "joined"}, %Socket{assigns: %{game_id: game_id}} = socket) do
    {:ok, game} = Game.get(game_id)
    {:noreply, assign(socket, game: game)}
  end
end
