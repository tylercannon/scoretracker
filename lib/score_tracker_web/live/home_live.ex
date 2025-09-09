defmodule ScoreTrackerWeb.HomeLive do
  use ScoreTrackerWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign(socket, user_id: session["user_id"])}
  end

  @impl true
  def render(%{user_id: _} = assigns) do
    ~H"""
    <div class="size-full flex flex-col items-center justify-center bg-background text-primary">
      <h1 class="text-3xl font-bold mb-24">Welcome to Score Tracker</h1>
      <div class="flex flex-col mt-2 gap-4">
        <.button type="button" phx-click={JS.show(to: "#new-game-modal")}>
          New Game
        </.button>
        <.button
          type="button"
          class="bg-secondary text-secondary-foreground hover:bg-secondary/80"
          phx-click={JS.show(to: "#join-game-modal")}
        >
          Join Game
        </.button>
      </div>
    </div>

    <.modal id="new-game-modal" on_cancel={JS.hide(to: "#new-game-modal")}>
      <div>
        <h2 class="text-xl font-bold mb-4 text-primary">New Game</h2>
        <.live_component
          id="create-game-form"
          module={ScoreTrackerWeb.CreateGameForm}
          user_id={@user_id}
          on_cancel={JS.hide(to: "#new-game-modal")}
        />
      </div>
    </.modal>

    <.modal id="join-game-modal" on_cancel={JS.hide(to: "#join-game-modal")}>
      <div>
        <h2 class="text-xl font-bold mb-4 text-white">Join Game</h2>
        <.live_component
          id="join-game-form"
          module={ScoreTrackerWeb.JoinGameForm}
          user_id={@user_id}
          on_cancel={JS.hide(to: "#join-game-modal")}
        />
      </div>
    </.modal>
    """
  end
end
