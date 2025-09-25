defmodule ScoreTracker.Cache do
  @moduledoc """
  Module used to interact with the application cache
  """

  def child_spec(_) do
    %{cache: %{url: cache_url}} = ScoreTracker.Config.get()

    children =
      Enum.map(0..(pool_size() - 1), fn index ->
        conn_name = conn_name(index)
        Supervisor.child_spec({Redix, {cache_url, [name: conn_name]}}, id: {Redix, conn_name})
      end)

    %{
      id: CacheSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  @doc """
  Wrapper around Redix.command/3, but using a random connection from the pool.
  """
  @spec command(Redix.command(), keyword()) ::
          {:ok, Redix.Protocol.redis_value()}
          | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}
  def command(command, opts \\ []), do: Redix.command(random_conn(), command, opts)

  @doc """
  Wrapper around Redix.command!/3, but using a random connection from the pool.
  """
  @spec command!(Redix.command(), keyword()) :: Redix.Protocol.redis_value()
  def command!(command, opts \\ []), do: Redix.command!(random_conn(), command, opts)

  # sobelow_skip ["DOS.BinToAtom"]
  defp conn_name(index), do: :"cache_#{index}"
  defp random_conn, do: 0..(pool_size() - 1) |> Enum.random() |> conn_name()
  defp pool_size, do: ScoreTracker.Config.get().cache.pool_size
end
