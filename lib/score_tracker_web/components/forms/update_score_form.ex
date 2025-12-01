defmodule ScoreTrackerWeb.UpdateScoreForm do
  @moduledoc """
  Form used to collect and update
  a player's score for a given round
  """

  use ScoreTrackerWeb, :live_component

  alias ScoreTracker.{GameManager, UpdateScore}

  @impl true
  def render(%{game_id: _, player_id: _, game_type: _, round: _, on_cancel: _} = assigns) do
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
          inputmode="numeric"
          field={f[:score]}
          label="Score"
        />
        <:actions>
          <.button
            type="button"
            class="bg-secondary text-secondary-foreground hover:bg-secondary/80"
            phx-click={@on_cancel}
          >
            Cancel
          </.button>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    game_type = assigns.game_type

    socket =
      socket
      |> assign(assigns)
      |> assign(form: to_form(UpdateScore.changeset(%UpdateScore{}, game_type)))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", attrs, socket) do
    game_type = socket.assigns.game_type

    form =
      %UpdateScore{}
      |> UpdateScore.changeset(game_type, attrs)
      |> to_form(action: :validate)

    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("save", attrs, socket) do
    game_type = socket.assigns.game_type

    socket =
      case UpdateScore.update(%UpdateScore{}, game_type, attrs) do
        {:ok, update_score} ->
          score_opts =
            update_score
            |> Map.from_struct()
            |> Map.merge(%{
              player_id: socket.assigns.player_id,
              game_id: socket.assigns.game_id,
              round: socket.assigns.round
            })
            |> Enum.to_list()

          case GameManager.update_player_score(GameManager, score_opts) do
            {:error, :not_found} ->
              attrs = Map.from_struct(update_score)

              form =
                %UpdateScore{}
                |> UpdateScore.changeset(game_type, attrs)
                |> Ecto.Changeset.add_error(:score, "Game not found")
                |> to_form(action: :validate)

              assign(socket, form: form)

            _ ->
              push_navigate(socket, to: ~p"/game/#{socket.assigns.game_id}")
          end

        {:error, changeset} ->
          assign(socket, form: to_form(changeset, action: :validate))
      end

    {:noreply, socket}
  end
end
