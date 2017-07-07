defmodule Gnat.ConnectionManager do
  use GenServer
  require Logger

  def start_link(settings, options \\ []), do: GenServer.start_link(__MODULE__, settings, options)

  def init(settings) do
    state = %{
      connection_settings: Map.fetch!(settings, :connection_settings),
      gnat: nil,
      reconnect_backoff: Map.get(settings, :reconnect_backoff, 2000),
      subscriptions: %Gnat.SubscriptionProxy{},
    }
    Process.flag(:trap_exit, true)
    send self(), :attempt_connection
    {:ok, state}
  end

  def handle_call(_call, _from, %{gnat: nil}=state), do: {:reply, {:error, :not_connected}, state}
  def handle_call(call, _from, %{gnat: gnat}=state) do
    try do
      result = GenServer.call(gnat, call)
      {:reply, result, state}
    catch
      :exit, reason -> {:reply, {:error, reason}, state}
      other -> {:reply, {:error, other}, state}
    end
  end

  def handle_info(:attempt_connection, state) do
    connection_config = random_connection_config(state)
    case Gnat.start_link(connection_config) do
      {:ok, gnat} -> {:noreply, %{state | gnat: gnat}}
      {:error, _err} -> {:noreply, %{state | gnat: nil}}
    end
  end

  def handle_info({:EXIT, _pid, reason}, %{gnat: nil}=state) do
    Logger.error "#{__MODULE__} failed to connect #{inspect reason}"
    Process.send_after(self(), :attempt_connection, state.reconnect_backoff)
    {:noreply, state}
  end
  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.error "#{__MODULE__} failed to connect #{inspect reason}"
    send self(), :attempt_connection
    {:noreply, state}
  end
  def handle_info(msg, state) do
    Logger.error "#{__MODULE__} received unexpected message #{inspect msg}"
    {:noreply, state}
  end

  defp random_connection_config(%{connection_settings: settings}), do: Enum.random(settings)
end
