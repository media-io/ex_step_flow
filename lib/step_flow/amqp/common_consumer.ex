defmodule StepFlow.Amqp.CommonConsumer do
  @doc false
  defmacro __using__(opts) do
    quote do
      use GenServer
      use AMQP

      @moduledoc false
      alias StepFlow.Amqp.Helpers

      def start_link do
        GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
      end

      def init(:ok) do
        rabbitmq_connect()
        # Connection.consume(unquote(opts).queue, unquote(opts).consumer)
      end

      # Confirmation sent by the broker after registering this process as a consumer
      def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, channel) do
        {:noreply, channel}
      end

      # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
      def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, channel) do
        {:stop, :normal, channel}
      end

      # Confirmation sent by the broker to the consumer process after a Basic.cancel
      def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, channel) do
        {:noreply, channel}
      end

      def handle_info(
            {:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}},
            channel
          ) do
        queue = unquote(opts).queue

        data =
          payload
          |> Jason.decode!()

        Logger.warn("#{__MODULE__}: receive message on queue: #{queue}")

        spawn(fn -> unquote(opts).consumer.(channel, tag, redelivered, data) end)
        {:noreply, channel}
      end

      def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
        {:ok, chan} = rabbitmq_connect()
        # {:noreply, :ok}
      end

      def terminate(_reason, state) do
        AMQP.Connection.close(state.connection)
      end

      def port_format(port) when is_integer(port) do
        Integer.to_string(port)
      end

      def port_format(port) do
        port
      end

      defp rabbitmq_connect do
        url = Helpers.get_amqp_connection_url()

        case AMQP.Connection.open(url) do
          {:ok, connection} ->
            init_amqp_connection(connection)
          {:error, message} ->
            Logger.error(
              "#{__MODULE__}: unable to connect to: #{url}, reason: #{inspect(message)}"
            )

            # Reconnection loop
            :timer.sleep(10_000)
            rabbitmq_connect()
        end
      end

      defp init_amqp_connection(connection) do
        Process.monitor(connection.pid)

        {:ok, channel} = AMQP.Channel.open(connection)
        queue = unquote(opts).queue

        exchange = AMQP.Exchange.topic(channel, "job_response", durable: true)

        AMQP.Queue.declare(channel, queue, durable: false)
        Logger.warn("#{__MODULE__}: bind #{queue}")
        AMQP.Queue.bind(channel, queue, "job_response", routing_key: queue)

        Logger.warn("#{__MODULE__}: connected to queue #{queue}")

        {:ok, _consumer_tag} = AMQP.Basic.consume(channel, queue)
        {:ok, channel}
      end
    end
  end
end
