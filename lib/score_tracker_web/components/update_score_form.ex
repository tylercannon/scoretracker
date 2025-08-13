defmodule ScoreTrackerWeb.UpdateScoreForm do
  use ScoreTrackerWeb, :live_component

  alias ScoreTracker.UpdateScore
  alias ScoreTracker.GameManager

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
        <.input
          id={"#{@player_id}-#{@round}-score"}
          type="number"
          field={f[:score]}
          label="Score"
        />
        <:actions>
          <.button type="button" phx-click={@on_cancel}>Cancel</.button>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(form: to_form(UpdateScore.changeset(%UpdateScore{})))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", attrs, socket) do
    form =
      %UpdateScore{}
      |> UpdateScore.changeset(attrs)
      |> to_form(action: :validate)

    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("save", attrs, socket) do
    socket =
      case UpdateScore.update(%UpdateScore{}, attrs) do
        {:ok, update_score} ->
          result =
            update_score
            |> Map.from_struct()
            |> Map.merge(%{
              player_id: socket.assigns.player_id,
              game_id: socket.assigns.game_id,
              round: socket.assigns.round
            })
            |> Enum.to_list()
            |> GameManager.update_player_score()

          case result do
            {:error, :not_found} ->
              attrs = Map.from_struct(update_score)

              form =
                %UpdateScore{}
                |> UpdateScore.changeset(attrs)
                |> Ecto.Changeset.add_error(:score, "Game not found")
                |> to_form(action: :validate)

              assign(socket, form: form)

            _ ->
              socket
              |> push_navigate(to: ~p"/game/#{socket.assigns.game_id}")
          end

        {:error, changeset} ->
          assign(socket, form: to_form(changeset, action: :validate))
      end

    {:noreply, socket}
  end
end
