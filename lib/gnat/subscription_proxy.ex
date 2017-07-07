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
    state = remove_or_update_subscription(state, sid, opts)
    {state, {:unsub, sid, opts}}
  end

  def receive_message(state, %{sid: sid}=message) do
    case Map.get(state.subscriptions, sid) do
      nil -> {:error, :no_such_subscription}
      %{consumer: pid} -> {state, {:send, pid, message}}
    end
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

  defp remove_or_update_subscription(state, sid, opts) do
    case Map.get(state.subscriptions, sid) do
      nil -> {:error, :unknown_subscription}
      subscription ->
        case Keyword.get(opts, :max_messages) do
          nil ->
            subscriptions = Map.delete(state.subscriptions, sid)
            consumers = remove_from_consumer(state.consumers, subscription)
            %{state | subscriptions: subscriptions, consumers: consumers}
          max_messages ->
            subscription = %{subscription | unsub_after: max_messages}
            subscriptions = Map.put(state.subscriptions, sid, %{sub #uhhhh this is all starting to seem like a bad idea at thsi point
        end
    end
  end

  defp subscription_opts(%{queue_group: nil, sid: sid}), do: [sid: sid]
  defp subscription_opts(%{queue_group: qg, sid: sid}), do: [queue_group: qg, sid: sid]
end
