defmodule RippleWeb.CreateGameForm do
  use RippleWeb, :live_component

  alias Ripple.CreateGame
  alias Ripple.GameManager

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(form: to_form(CreateGame.changeset(%CreateGame{})))

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
        <.input field={f[:host_name]} label="Host" />
        <.input field={f[:game_mode]} label="Game Mode" />
        <.input field={f[:max_players]} label="Max Players" />
        <.input field={f[:max_rounds]} label="Max Rounds" />
        <:actions>
          <.button type="button" phx-click={@on_cancel}>Cancel</.button>
          <.button>Create</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", attrs, socket) do
    form =
      %CreateGame{}
      |> CreateGame.changeset(attrs)
      |> to_form(action: :validate)

    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("save", attrs, socket) do
    socket =
      case CreateGame.update(%CreateGame{}, attrs) do
        {:ok, create_game} ->
          game_id =
            create_game
            |> Map.from_struct()
            |> Map.put(:host_id, socket.assigns.user_id)
            |> Enum.to_list()
            |> GameManager.create_game()

          socket
          |> assign(game_id: game_id)
          |> push_navigate(to: ~p"/game/#{game_id}")

        {:error, changeset} ->
          assign(socket, form: to_form(changeset, action: :validate))
      end

    {:noreply, socket}
  end
end
