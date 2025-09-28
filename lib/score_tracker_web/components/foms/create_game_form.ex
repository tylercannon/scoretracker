defmodule ScoreTrackerWeb.CreateGameForm do
  @moduledoc """
  Form used to allow a game host to
  customize and start a new game
  """

  use ScoreTrackerWeb, :live_component

  alias ScoreTracker.{CreateGame, GameManager, Player}

  @impl true
  def render(%{on_cancel: _, max_players_reached?: _, show_players?: _} = assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        for={@form}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={f[:host_name]} label="Host" placeholder="Host Name" />
        <.input
          field={f[:game_mode]}
          type="select"
          label="Game Mode"
          options={[Scorekeeper: "scorekeeper", Party: "party"]}
        />
        <.input field={f[:allow_spectators]} label="Allow Spectators?" type="checkbox" />
        <.input
          field={f[:game_type]}
          type="select"
          label="Game Type"
          options={[Rummy: "rummy", Ripple: "ripple", Custom: "custom"]}
        />
        <div :if={@custom_game?} class="space-y-4">
          <.input field={f[:max_players]} label="Max Players" />
          <.input field={f[:max_rounds]} label="Max Rounds" />
        </div>
        <div :if={@show_players?} class="space-y-4">
          <span class="text-sm font-semibold leading-6 text-foreground">Players</span>
          <.inputs_for :let={pf} field={@form[:players]} as={:players}>
            <input type="hidden" name="players_sort[]" value={pf.index} />
            <div class="relative">
              <.input type="text" field={pf[:name]} placeholder="Player Name" class="pr-10" />
              <button
                :if={String.length(Ecto.Changeset.get_field(pf.source, :name) || "") > 0}
                type="button"
                name="players_drop[]"
                value={pf.index}
                phx-click={JS.dispatch("change")}
                class="absolute top-2 right-3 cursor-pointer"
              >
                <.icon name="hero-x-mark" class="size-6 text-foreground" />
              </button>
            </div>
          </.inputs_for>
          <input type="hidden" name="players_drop[]" />
          <.button
            :if={!@max_players_reached?}
            type="button"
            name="players_sort[]"
            class="bg-secondary text-secondary-foreground hover:bg-secondary/80"
            value="new"
            phx-click={JS.dispatch("change")}
          >
            Add Player
          </.button>
        </div>
        <:actions>
          <.button
            type="button"
            class="bg-secondary text-secondary-foreground hover:bg-secondary/80"
            phx-click={@on_cancel}
          >
            Cancel
          </.button>
          <.button>Create</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset =
      CreateGame.changeset(%CreateGame{
        game_mode: :scorekeeper,
        game_type: :rummy,
        players: [%Player{name: ""}]
      })

    show_players? = Ecto.Changeset.get_field(changeset, :game_mode) == :scorekeeper
    custom_game? = Ecto.Changeset.get_field(changeset, :game_type) == :custom

    socket =
      socket
      |> assign(assigns)
      |> assign(
        form: to_form(changeset),
        show_players?: show_players?,
        custom_game?: custom_game?,
        max_players_reached?: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", attrs, socket) do
    changeset = CreateGame.changeset(%CreateGame{}, attrs)
    show_players? = Ecto.Changeset.get_field(changeset, :game_mode) == :scorekeeper
    custom_game? = Ecto.Changeset.get_field(changeset, :game_type) == :custom

    players_count =
      changeset
      |> Ecto.Changeset.get_field(:players)
      |> Enum.count()

    max_players = Ecto.Changeset.get_field(changeset, :max_players)
    max_players_reached? = players_count >= max_players

    {:noreply,
     assign(socket,
       form: to_form(changeset, action: :validate),
       show_players?: show_players?,
       custom_game?: custom_game?,
       max_players_reached?: max_players_reached?
     )}
  end

  @impl true
  def handle_event("save", attrs, socket) do
    socket =
      case CreateGame.update(%CreateGame{}, attrs) do
        {:ok, create_game} ->
          game_opts =
            create_game
            |> Map.from_struct()
            |> Map.put(:host_id, socket.assigns.user_id)
            |> Map.update(:players, [], &Enum.map(&1, fn player -> player.name end))
            |> Enum.to_list()

          game_id = GameManager.create_game(GameManager, game_opts)

          socket
          |> assign(game_id: game_id)
          |> push_navigate(to: ~p"/game/#{game_id}")

        {:error, changeset} ->
          assign(socket, form: to_form(changeset, action: :validate))
      end

    {:noreply, socket}
  end
end
