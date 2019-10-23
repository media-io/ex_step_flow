defmodule StepFlow.Amqp.Connection do
  require Logger

  @moduledoc false

  @submit_exchange "job_submit"

  use GenServer
  alias StepFlow.Amqp.Helpers

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def consume(queue, callback) do
    GenServer.cast(__MODULE__, {:consume, queue, callback})
  end

  def publish(queue, message) do
    GenServer.cast(__MODULE__, {:publish, queue, message})
  end

  def publish_json(queue, message) do
    publish(queue, message |> Jason.encode!())
  end

  def init(:ok) do
    Logger.warn("#{__MODULE__} init")
    rabbitmq_connect()
  end

  def handle_cast({:publish, queue, message}, conn) do
    Logger.warn("#{__MODULE__}: publish message on queue: #{queue}")
    AMQP.Basic.publish(conn.channel, @submit_exchange, queue, message)
    {:noreply, conn}
  end

  def handle_cast({:consume, queue, _callback}, conn) do
    Logger.warn("#{__MODULE__}: consume messages on queue: #{queue}")
    # AMQP.Queue.declare(conn.channel, queue, durable: false)
    {:ok, _consumer_tag} = AMQP.Basic.consume(conn, queue)
    {:noreply, conn}
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
    {:ok, chan} = rabbitmq_connect()
    {:noreply, chan}
  end

  def terminate(_reason, state) do
    AMQP.Connection.close(state.connection)
  end

  defp rabbitmq_connect do
    url = Helpers.get_amqp_connection_url()

    case AMQP.Connection.open(url) do
      {:ok, connection} ->
        init_amqp_connection(connection)

      {:error, message} ->
        Logger.error("#{__MODULE__}: unable to connect to: #{url}, reason: #{inspect(message)}")

        # Reconnection loop
        :timer.sleep(10_000)
        rabbitmq_connect()
    end
  end

  defp init_amqp_connection(connection) do
    Process.monitor(connection.pid)

    {:ok, channel} = AMQP.Channel.open(connection)
    # AMQP.Queue.declare(channel, queue)
    # Logger.warn("#{__MODULE__}: connected to queue #{queue}")

    AMQP.Exchange.topic(channel, @submit_exchange,
      durable: true,
      arguments: [{"alternate-exchange", :longstr, "job_queue_not_found"}]
    )

    AMQP.Exchange.fanout(channel, "job_queue_not_found", durable: true)

    AMQP.Queue.declare(channel, "job_queue_not_found")
    AMQP.Queue.bind(channel, "job_queue_not_found", "job_queue_not_found")

    {:ok, %{channel: channel, connection: connection}}
  end
end
