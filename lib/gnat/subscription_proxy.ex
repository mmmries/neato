defmodule Gnat.SubscriptionProxy do
  @moduledoc false

  defstruct consumers: %{}, subscriptions: %{}, sid_counter: 1

  def new, do: %__MODULE__{}

  def sub(state, consumer, topic, opts) do
    {state, sid} = next_sid(state)
    subscription = %{topic: topic, queue_group: Keyword.get(opts, :queue_group), sid: sid, consumer: consumer, unsub_after: nil}
    consumers = append_subscription_to_consumers(state.consumers, subscription)
    subscriptions = Map.put(state.subscriptions, sid, subscription)
    state = %{state | consumers: consumers, subscriptions: subscriptions}
    {state, {:sub, self(), topic, subscription_opts(subscription)}}
  end

  def unsub(state, sid, opts) do
    case Map.get(state.subscriptions, sid) do
      nil -> {:error, :unknown_subscription}
      subscription ->
        subscriptions = Map.delete(state.subscriptions, sid)
        consumers = remove_from_consumer(state.consumers, subscription)
        state = %{state | subscriptions: subscriptions, consumers: consumers}
        {state, {:unsub, sid, []}}
    end
  end

  def receive_message(state, message) do
  end

  def connection_lost(state) do
  end

  def process_down(state, pid) do
  end

  defp append_subscription_to_consumers(consumers, %{consumer: consumer}=subscription) do
    subscriptions = case Map.get(consumers, consumer) do
      nil -> [subscription]
      subscriptions -> [subscription | subscriptions]
    end
    Map.put(consumers, consumer, subscriptions)
  end

  defp next_sid(%{sid_counter: counter}=state) do
    {%{state | sid_counter: counter + 1}, counter}
  end

  defp remove_from_consumer(consumers, %{consumer: consumer, sid: sid}) do
    case Map.get(consumers, consumer) do
      [%{sid: ^sid}] -> Map.delete(consumers, consumer)
      subscriptions ->
        subscriptions = Enum.reject(consumers[consumer], &( &1.sid == sid ))
        Map.put(consumers, consumer, subscriptions)
    end
  end

  defp subscription_opts(%{queue_group: nil, sid: sid}), do: [sid: sid]
  defp subscription_opts(%{queue_group: qg, sid: sid}), do: [queue_group: qg, sid: sid]
end
