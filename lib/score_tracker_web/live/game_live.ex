defmodule ScoreTrackerWeb.GameLive do
  use ScoreTrackerWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias ScoreTracker.{GameManager, GameType, Player}
  alias ScoreTrackerWeb.GameDetails

  @impl Phoenix.LiveView
  def render(%{is_host: _} = assigns) do
    ~H"""
    <div
      class="min-size-full flex flex-col items-center p-4 pb-12 text-primary bg-background"
      phx-mounted={JS.remove_class("overflow-hidden", to: "body")}
    >
      <div class="w-full flex items-center justify-between gap-4">
        <h1 class="text-xl font-bold">
          {GameType.friendly_name(@game.game_type, @game.custom_name)}
        </h1>
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-1">
            <span>ID:</span>
            <span class="font-bold">{@game_id}</span>
          </div>
          <div
            phx-hook="CopyToClipboard"
            id="game-id-wrapper"
            data-copy-text={@game_id}
          >
            <button
              type="button"
              aria-label="Copy to clipboard"
              class="flex items-center cursor-pointer hover:text-primary/80"
            >
              <.icon name="hero-clipboard-document" class="size-5" />
            </button>
          </div>
          <div
            phx-hook="ShareLink"
            id="share-link-wrapper"
            data-share-url={@share_url}
            data-share-title={"Share #{GameType.friendly_name(@game.game_type, @game.custom_name)} game link"}
            data-share-text={"Join #{GameType.friendly_name(@game.game_type, @game.custom_name)}"}
          >
            <button
              type="button"
              aria-label="Share game link"
              class="flex items-center cursor-pointer hover:text-primary/80"
            >
              <.icon name="hero-share" class="size-5" />
            </button>
          </div>
        </div>
      </div>
      <div class="w-full my-4 flex justify-center gap-4">
        <.stat_card label="Round" value={"#{@game.round} of #{@game.max_rounds}"} />
        <.stat_card label="Status" value={GameDetails.get_status(@game.status)} />
      </div>
      <div class="w-full">
        <div :if={GameType.round_info(@game.game_type, @game.round)} class="mb-4">
          <h2 class="text-lg font-bold mb-2">Round Info</h2>
          <div class="flex flex-col gap-2">
            <p :for={line <- GameType.round_info(@game.game_type, @game.round)} class="mx-4">
              {line}
            </p>
          </div>
        </div>
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-bold">Scoreboard</h2>
          <.button
            :if={GameDetails.host?(@game, @user_id) and @game.status == :waiting_for_players}
            type="button"
            phx-click="start_game"
          >
            Start Game
          </.button>
          <.next_round
            :if={GameDetails.host?(@game, @user_id) and GameDetails.in_progress?(@game)}
            game={@game}
            user_id={@user_id}
          />
          <.play_again :if={GameDetails.host?(@game, @user_id) and GameDetails.complete?(@game)} />
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-center">
            <thead class="bg-background text-primary">
              <tr>
                <th class="p-3">Player</th>
                <th class="md:hidden p-3">Total</th>
                <th
                  :for={round <- 1..@game.max_rounds}
                  class={[
                    "p-3",
                    round == @game.round && "border-x-2 border-t-2 border-primary text-lg font-bold"
                  ]}
                >
                  {round}
                </th>
                <th class="hidden md:table-cell p-3">Total</th>
              </tr>
            </thead>
            <tbody class="border border-border">
              <tr
                :for={%Player{id: player_id, name: player_name} <- @game.players}
                class="group hover:bg-primary hover:text-primary-foreground"
              >
                <td class="p-3 font-medium">{player_name}</td>
                <td class="md:hidden p-3 font-bold">
                  {GameDetails.player_total_score(player_id, @game)}
                </td>
                <td
                  :for={round <- 1..@game.max_rounds}
                  class={[
                    "p-3",
                    round == @game.round &&
                      "border-x-2 border-primary text-lg font-bold group-last:border-b-2 group-last:border-primary"
                  ]}
                >
                  <div class="flex gap-2 items-center justify-center">
                    <.edit_score
                      :if={GameDetails.user_score_editable?(@game, player_id, @user_id, round)}
                      player_id={player_id}
                      player_name={player_name}
                      round={round}
                    />
                    {Map.get(
                      @game.scores[player_id],
                      to_string(round),
                      if(GameDetails.user_score_editable?(@game, player_id, @user_id, round),
                        do: nil,
                        else: "-"
                      )
                    )}
                  </div>
                </td>
                <td class="hidden md:table-cell p-3 font-bold">
                  {GameDetails.player_total_score(player_id, @game)}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <.modal
        :if={is_map(@edit_score_details)}
        id="edit-score-modal"
        on_cancel={hide_modal("edit-score-modal") |> JS.push("cancel_edit_score")}
        show={true}
      >
        <div>
          <h2 class="text-xl font-bold mb-4 text-primary">
            Edit {@edit_score_details.player_name}'s Round {@edit_score_details.round} Score
          </h2>
          <.live_component
            id="edit-score-form"
            module={ScoreTrackerWeb.UpdateScoreForm}
            game_id={@game_id}
            game_type={@game.game_type}
            player_id={@edit_score_details.player_id}
            round={@edit_score_details.round}
            on_cancel={hide_modal("edit-score-modal") |> JS.push("cancel_edit_score")}
          />
        </div>
      </.modal>
      <.winner_modal
        :if={GameDetails.complete?(@game)}
        winner={GameDetails.winner(@game)}
      />
    </div>
    """
  end

  defp stat_card(%{label: _, value: _} = assigns) do
    ~H"""
    <div class="grow bg-card p-4 rounded-lg border border-border text-card-foreground text-center">
      <p class="text-sm">{@label}</p>
      <p class="text-2xl font-bold">{@value}</p>
    </div>
    """
  end

  defp next_round(%{game: _, user_id: _} = assigns) do
    ~H"""
    <.button type="button" phx-click={show_modal("go-to-next-round")}>
      {if @game.round < @game.max_rounds, do: "Next Round", else: "End Game"}
    </.button>
    <.modal id="go-to-next-round" on_cancel={hide_modal("go-to-next-round")}>
      <div class="text-primary">
        <h2 class="text-xl font-bold mb-4">
          {if @game.round < @game.max_rounds,
            do: "Go to Round #{@game.round + 1}",
            else: "End Game"}?
        </h2>
        <p>
          {if GameDetails.any_missing_player_round_score?(@game),
            do:
              Enum.join(
                [
                  "There are players without a score for the current round.",
                  "Are you sure you want to progress without updating their scores?"
                ],
                " "
              ),
            else: "Are you sure you want to progress to the next round?"}
        </p>
        <div class="flex justify-between mt-5">
          <.button
            type="button"
            class="bg-secondary text-secondary-foreground hover:bg-secondary/80"
            phx-click={hide_modal("go-to-next-round")}
          >
            Cancel
          </.button>
          <.button
            type="button"
            phx-click={hide_modal("go-to-next-round") |> JS.push("next_round")}
          >
            Continue
          </.button>
        </div>
      </div>
    </.modal>
    """
  end

  defp play_again(%{} = assigns) do
    ~H"""
    <.button type="button" phx-click={show_modal("play-again")}>
      Play Again
    </.button>
    <.modal id="play-again" on_cancel={hide_modal("play-again")}>
      <div class="text-primary">
        <h2 class="text-xl font-bold mb-4">Play Again?</h2>
        <p>
          This will clear every player's score from the scoreboard
          and reset the game to round 1.
        </p>
        <div class="flex justify-between mt-5">
          <.button
            type="button"
            class="bg-secondary text-secondary-foreground hover:bg-secondary/80"
            phx-click={hide_modal("play-again")}
          >
            Cancel
          </.button>
          <.button
            type="button"
            phx-click={hide_modal("play-again") |> JS.push("play_again")}
          >
            Continue
          </.button>
        </div>
      </div>
    </.modal>
    """
  end

  defp edit_score(%{player_id: _, player_name: _, round: _} = assigns) do
    ~H"""
    <button
      type="button"
      class="flex items-center justify-center gap-1 px-4 hover:cursor-pointer"
      phx-click={
        JS.push("edit_score",
          value: %{
            player_id: @player_id,
            player_name: @player_name,
            round: @round
          }
        )
      }
    >
      <span class="hero-pencil-square-mini"></span>
    </button>
    """
  end

  defp winner_modal(%{winner: _} = assigns) do
    ~H"""
    <.modal
      id="winner-modal"
      on_cancel={hide_modal("winner-modal")}
      show={true}
    >
      <div>
        <h2 class="text-xl font-bold mb-4 text-primary">
          {if(@winner.type == :tie, do: "It was a tie!", else: "#{@winner.winner} won!")}
        </h2>
        <p>
          {if(@winner.type == :tie,
            do: "#{GameDetails.format_winners(@winner.winners)} tied",
            else: "#{@winner.winner} won"
          )} with a score of {@winner.score}.
        </p>
        <div class="flex justify-end mt-5">
          <.button type="button" phx-click={hide_modal("winner-modal")}>
            Close
          </.button>
        </div>
      </div>
    </.modal>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"game_id" => game_id}, session, socket) do
    case GameDetails.get_game(game_id) do
      {:ok, game} ->
        user_id = session["user_id"]
        is_host = GameDetails.host?(game, user_id)

        if connected?(socket) do
          Phoenix.PubSub.subscribe(ScoreTracker.PubSub, GameDetails.topic(game_id))
        end

        send(self(), :after_mount)

        socket =
          assign(socket, %{
            user_id: user_id,
            game_id: game_id,
            game: game,
            is_host: is_host,
            edit_score_details: nil
          })

        {:ok, socket}

      {:error, :not_found} ->
        {:ok, push_navigate(socket, to: ~p"/")}
    end
  end

  @impl Phoenix.LiveView
  def handle_params(_params, uri, socket) do
    parsed_uri = URI.parse(uri)
    encoded_query = URI.encode_query(%{"join" => socket.assigns.game_id})
    share_uri = %{parsed_uri | path: nil, query: encoded_query}
    share_url = URI.to_string(share_uri)

    {:noreply, assign(socket, share_url: share_url)}
  end

  @impl Phoenix.LiveView
  def terminate(_reason, %Socket{assigns: %{game_id: game_id}}) do
    Phoenix.PubSub.unsubscribe(ScoreTracker.PubSub, GameDetails.topic(game_id))
  end

  def terminate(_reason, _socket), do: :ok

  @impl Phoenix.LiveView
  def handle_event(
        "start_game",
        _params,
        %Socket{assigns: %{is_host: host?, game_id: game_id}} = socket
      ) do
    if host? do
      {:ok, status} = GameManager.start_game(GameManager, game_id: game_id)

      ScoreTrackerWeb.Endpoint.broadcast(GameDetails.topic(game_id), "start_game", %{
        status: status
      })
    end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "next_round",
        _params,
        %Socket{assigns: %{is_host: host?, game_id: game_id}} = socket
      ) do
    if host? do
      {:ok, _} = GameManager.advance_to_next_round(GameManager, game_id: game_id)
      ScoreTrackerWeb.Endpoint.broadcast(GameDetails.topic(game_id), "next_round", %{})
    end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "edit_score",
        %{"player_id" => player_id, "player_name" => player_name, "round" => round},
        %Socket{assigns: %{is_host: host?, game: game, user_id: user_id}} = socket
      ) do
    if host? or GameDetails.user_score_editable?(game, player_id, user_id, round) do
      edit_score_details = %{
        player_id: player_id,
        player_name: player_name,
        round: round
      }

      {:noreply, assign(socket, edit_score_details: edit_score_details)}
    else
      {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("cancel_edit_score", _params, socket) do
    {:noreply, assign(socket, edit_score_details: nil)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "play_again",
        _params,
        %Socket{assigns: %{is_host: host?, game_id: game_id}} = socket
      ) do
    if host? do
      :ok = GameManager.reset_game(GameManager, game_id: game_id)
      ScoreTrackerWeb.Endpoint.broadcast(GameDetails.topic(game_id), "play_again", %{})
    end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(:after_mount, %Socket{assigns: %{game_id: game_id}} = socket) do
    ScoreTrackerWeb.Endpoint.broadcast_from(self(), GameDetails.topic(game_id), "joined", %{})
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(%{event: "start_game", payload: %{status: status}}, socket) do
    {:noreply, update(socket, :game, &Map.put(&1, :status, status))}
  end

  @impl Phoenix.LiveView
  def handle_info(%{event: event}, %Socket{assigns: %{game_id: game_id}} = socket)
      when event in ["joined", "next_round", "play_again", "score_updated"] do
    {:ok, game} = GameDetails.get_game(game_id)
    {:noreply, assign(socket, game: game, edit_score_details: nil)}
  end
end
