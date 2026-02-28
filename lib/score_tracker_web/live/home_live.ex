defmodule ScoreTrackerWeb.HomeLive do
  use ScoreTrackerWeb, :live_view

  alias ScoreTracker.JoinGame
  alias ScoreTrackerWeb.GameDetails

  @impl Phoenix.LiveView
  def render(%{user_id: _} = assigns) do
    ~H"""
    <div class="size-full flex flex-col items-center justify-center bg-background text-primary">
      <h1 class="text-3xl text-center font-bold mb-24">Welcome to<br />Score Tracker</h1>
      <div class="flex flex-col mt-2 gap-4">
        <.button type="button" phx-click={show_modal("new-game-modal")}>
          New Game
        </.button>
        <.button
          type="button"
          class="bg-secondary text-secondary-foreground hover:bg-secondary/80"
          phx-click={show_modal("join-game-modal")}
        >
          Join Game
        </.button>
      </div>
    </div>

    <.modal id="new-game-modal" on_cancel={hide_modal("new-game-modal")}>
      <div>
        <h2 class="text-xl font-bold mb-4 text-primary">New Game</h2>
        <.live_component
          id="create-game-form"
          module={ScoreTrackerWeb.CreateGameForm}
          user_id={@user_id}
          on_cancel={hide_modal("new-game-modal")}
        />
      </div>
    </.modal>

    <.modal id="join-game-modal" on_cancel={hide_modal("join-game-modal")} show={@show_join_modal}>
      <div>
        <h2 class="text-xl font-bold mb-4 text-primary">Join Game</h2>
        <.live_component
          id="join-game-form"
          module={ScoreTrackerWeb.JoinGameForm}
          user_id={@user_id}
          game_id={@game_id}
          on_cancel={hide_modal("join-game-modal")}
        />
      </div>
    </.modal>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    {:ok, assign(socket, user_id: session["user_id"], game_id: nil, show_join_modal: false)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"join" => game_id}, _uri, socket) do
    with true <- JoinGame.valid_game_id?(game_id),
         {:ok, game} <- GameDetails.get_game(game_id) do
      socket =
        if GameDetails.accessible?(game, socket.assigns.user_id) do
          push_navigate(socket, to: ~p"/game/#{game_id}")
        else
          assign(socket, game_id: game_id, show_join_modal: true)
        end

      {:noreply, socket}
    else
      _ -> {:noreply, push_patch(socket, to: "/")}
    end
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket), do: {:noreply, socket}
end
