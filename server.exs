defmodule EchoServer do
  def run(gnat) do
    spawn(fn -> init(gnat) end)
  end

  def init(gnat) do
    Gnat.sub(gnat, self(), "echo", queue_group: "bench")
    loop(gnat)
  end

  def loop(gnat) do
    receive do
      {:msg, %{topic: "echo", reply_to: reply_to, body: "ping"}} ->
        spawn(fn ->
          Gnat.pub(gnat, reply_to, "pong")
        end)
      other ->
        IO.puts "server received: #{inspect other}"
    end

    loop(gnat)
  end

  def wait_loop do
    :timer.sleep(1_000)
    wait_loop()
  end
end

(1..1) |> Enum.map(fn(_i) ->
  {:ok, gnat} = Gnat.start_link()
  EchoServer.run(gnat)
end)

EchoServer.wait_loop()
