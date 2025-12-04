defmodule ScoreTrackerWeb.JoinGameForm do
  @moduledoc """
  Form used to handle player attempts
  to join an existing game
  """

  use ScoreTrackerWeb, :live_component

  alias ScoreTracker.{GameManager, JoinGame}
  alias ScoreTrackerWeb.GameDetails

  @impl Phoenix.LiveComponent
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
          <.button
            type="button"
            class="bg-secondary text-secondary-foreground hover:bg-secondary/80"
            phx-click={@on_cancel}
          >
            Cancel
          </.button>
          <.button>Join</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    game_id = Map.get(assigns, :game_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(form: to_form(JoinGame.changeset(%JoinGame{game_id: game_id})))

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", attrs, socket) do
    form =
      %JoinGame{}
      |> JoinGame.changeset(attrs)
      |> to_form(action: :validate)

    {:noreply, assign(socket, form: form)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", attrs, socket) do
    socket =
      case JoinGame.update(%JoinGame{}, attrs) do
        {:ok, join_game} ->
          player_opts =
            join_game
            |> Map.from_struct()
            |> Map.put(:player_id, socket.assigns.user_id)
            |> Enum.to_list()

          case GameManager.add_player(GameManager, player_opts) do
            {:error, error_code} ->
              message = GameDetails.get_join_error_message(error_code)
              attrs = Map.from_struct(join_game)

              form =
                %JoinGame{}
                |> JoinGame.changeset(attrs)
                |> Ecto.Changeset.add_error(:game_id, message)
                |> to_form(action: :validate)

              assign(socket, form: form)

            _ ->
              socket
              |> assign(game_id: join_game.game_id)
              |> push_navigate(to: ~p"/game/#{join_game.game_id}")
          end

        {:error, changeset} ->
          assign(socket, form: to_form(changeset, action: :validate))
      end

    {:noreply, socket}
  end
end
