defmodule RippleWeb.JoinGameForm do
  use RippleWeb, :live_component

  alias Ripple.JoinGame
  alias Ripple.GameManager

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(form: to_form(JoinGame.changeset(%JoinGame{})))

    {:ok, socket}
  end

  @impl true
  def render(%{on_cancel: _} = assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        for={@form}
        phx-target={@myself}
        phx-change={JS.push("validate")}
        phx-submit="save"
      >
        <.input field={f[:player_name]} label="Name" />
        <.input field={f[:game_id]} label="Game ID" />
        <:actions>
          <.button type="button" phx-click={@on_cancel}>Cancel</.button>
          <.button>Join</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", attrs, socket) do
    form =
      %JoinGame{}
      |> JoinGame.changeset(attrs)
      |> to_form(action: :validate)

    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("save", attrs, socket) do
    socket =
      case JoinGame.update(%JoinGame{}, attrs) do
        {:ok, join_game} ->
          :ok =
            join_game
            |> Map.from_struct()
            |> Map.put(:player_id, socket.assigns.user_id)
            |> Enum.to_list()
            |> GameManager.add_player()

          socket
          |> assign(game_id: join_game.game_id)
          |> push_navigate(to: ~p"/game/#{join_game.game_id}")

        {:error, changeset} ->
          assign(socket, form: to_form(changeset, action: :validate))
      end

    {:noreply, socket}
  end
end
