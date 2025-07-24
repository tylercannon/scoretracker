defmodule RippleWeb.HomeLive do
  use RippleWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="w-screen h-screen flex flex-col items-center justify-center bg-slate-600 text-white">
      <h1>Welcome to Ripple</h1>
      <div class="flex flex-col mt-2 gap-4">
        <button phx-click={JS.show(to: "#new-game-modal")} class="p-2 rounded-md bg-teal-400">
          New Game
        </button>
        <button class="p-2 rounded-md bg-cyan-400">
          Join Game
        </button>
      </div>
    </div>

    <.modal id="new-game-modal" on_cancel={JS.hide(to: "#new-game-modal")}>
      <div>
        <h2 class="text-xl font-bold mb-4 text-white">New Game</h2>
        <.live_component
          id="create-game-form"
          module={RippleWeb.CreateGameForm}
          on_cancel={JS.hide(to: "#new-game-modal")}
        />
      </div>
    </.modal>
    """
  end
end
