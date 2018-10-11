{:ok, manager_pid} = Gnat.ConnectionSupervisor.start_link(%{name: :gnat, backoff_period: 4_000, connection_settings: [%{}]})

{:ok, _pid} = Gnat.ConsumerSupervisor.start_link(%{connection_name: :gnat, consuming_function: {EchoServer, :handle}, subscription_topics: [%{topic: "echo", queue_group: "echo"}]}, name: :consumer)

defmodule EchoServer do
  def handle(%{body: body, reply_to: reply_to}) do
    Gnat.pub(:gnat, reply_to, body)
  end

  def wait_loop do
    :timer.sleep(1_000)
    wait_loop()
  end
end

EchoServer.wait_loop()
