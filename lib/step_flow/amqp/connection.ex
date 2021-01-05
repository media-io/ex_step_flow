defmodule StepFlow.Amqp.Connection do
  require Logger

  @moduledoc false

  @submit_exchange "job_submit"

  use GenServer
  alias StepFlow.Amqp.Helpers
  alias StepFlow.Jobs
  alias StepFlow.Jobs.Status
  alias StepFlow.Workflows
  alias StepFlow.Workflows.StepManager

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def consume(queue, callback) do
    GenServer.cast(__MODULE__, {:consume, queue, callback})
  end

  def publish(queue, message, options) do
    GenServer.cast(__MODULE__, {:publish, queue, message, options})
  end

  # def publish_json(queue, message) do
  #   publish(queue, message |> Jason.encode!())
  # end

  def init(:ok) do
    Logger.warn("#{__MODULE__} init")
    rabbitmq_connect()
  end

  def handle_cast({:publish, queue, message, options}, conn) do
    Logger.warn("#{__MODULE__}: publish message on queue: #{queue} #{message}")
    AMQP.Basic.publish(conn.channel, @submit_exchange, queue, message, options)
    {:noreply, conn}
  end

  # def handle_cast({:consume, queue, _callback}, conn) do
  #   Logger.warn("#{__MODULE__}: consume messages on queue: #{queue}")
  #   # AMQP.Queue.declare(conn.channel, queue, durable: false)
  #   {:ok, _consumer_tag} = AMQP.Basic.consume(conn, queue)
  #   {:noreply, conn}
  # end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
    {:ok, chan} = rabbitmq_connect()
    {:noreply, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info(
        {:basic_deliver, payload, %{delivery_tag: tag, redelivered: _redelivered} = _headers},
        channel
      ) do
    data =
      payload
      |> Jason.decode!()

    job_id = Map.get(data, "job_id")

    try do
      Jobs.get_job(job_id)
    rescue
      e in Ecto.NoResultsError ->
        Logger.error("Cannot retrieve Job")

      e ->
        AMQP.Basic.reject(channel.channel, tag, requeue: true)
    end

    case Jobs.get_job(job_id) do
      nil ->
        AMQP.Basic.reject(channel.channel, tag, requeue: true)

      _ ->
        Logger.error("Job queue not found #{inspect(payload)}")
        description = "No worker is started with this queue name."
        Status.set_job_status(job_id, :error, %{message: description})
        Workflows.notification_from_job(job_id, description)
        AMQP.Basic.ack(channel.channel, tag)
    end

    {:noreply, channel}
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
    AMQP.Basic.consume(channel, "job_queue_not_found")

    {:ok, %{channel: channel, connection: connection}}
  end
end
