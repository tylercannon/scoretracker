defmodule RippleWeb.GameLive do
  use RippleWeb, :live_view

  def mount(%{"game_id" => game_id}, session, socket) do
    # todo: handle invalid game ids
    {:ok, game} = Ripple.GameManager.get_game(game_id)
    user_id = session["user_id"]
    is_host = game.host_id == user_id

    socket =
      assign(socket, %{
        user_id: user_id,
        game_id: game_id,
        game: game,
        is_host: is_host
      })

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="w-100 h-100 flex flex-col items-center justify-center p-4">
      <h1 class="text-xl font-bold mb-4">Game Details</h1>
      <div class="flex flex-col gap-2">
        <span>Is Host: {@is_host}</span>
        <span>Round: {@game.round}</span>
        <span>Status: {@game.status}</span>
        <span>Max Players: {@game.max_players}</span>
        <span>Max Rounds: {@game.max_rounds}</span>
      </div>
    </div>
    """
  end
end
