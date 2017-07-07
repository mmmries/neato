defmodule Gnat.SubscriptionProxyTest do
  use ExUnit.Case, async: true
  import Gnat.SubscriptionProxy

  test "recording a sub and unsub" do
    pid = spawn(fn -> :noop end)
    my_pid = self()
    {state, {:sub, ^my_pid, "topic", [sid: sid]}} = new() |> sub(pid, "topic", [])
    assert Map.has_key?(state.consumers, pid)
    assert Map.has_key?(state.subscriptions, sid)
    {state, {:sub, ^my_pid, "topic", [sid: sid2]}} = sub(state, pid, "topic", [])
    {state, {:unsub, sid, []}} = unsub(state, sid, [])
    assert Map.has_key?(state.consumers, pid)
    refute Map.has_key?(state.subscriptions, sid)
    assert Map.has_key?(state.subscriptions, sid2)
    {state, {:unsub, ^sid2, []}} = unsub(state, sid2, [])
    refute Map.has_key?(state.consumers, pid)
    refute Map.has_key?(state.subscriptions, sid2)
  end

  test "receiving messages" do
    pid = spawn(fn -> :noop end)
    my_pid = self()
    {state, {:sub, ^my_pid, "topic", [sid: sid]}} = new() |> sub(pid, "topic", [])
    message = %{body: "ohai", topic: "topic", sid: sid, reply_to: nil}
    {^state, {:send, ^pid, ^message}} = receive_message(state, message)
  end

  test "unsub with max messages" do
    pid = spawn(fn -> :noop end)
    {state, {:sub, _my_pid, "topic", [sid: sid]}} = new() |> sub(pid, "topic", [])
    message = %{body: "ohai", topic: "topic", sid: sid, reply_to: nil}
    {state, {:unsub, ^sid, [max_messages: 2]}} = unsub(state, sid, [max_messages: 2])
    assert Map.has_key?(state.consumers, pid)
    {state, _send} = receive_message(state, message)
    assert Map.has_key?(state.consumers, pid)
    {state, _send} = receive_message(state, message)
    refute Map.has_key?(state.consumers, pid)
  end
end
