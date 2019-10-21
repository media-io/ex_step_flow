defmodule StepFlow.Amqp.CommonConsumer do
  @doc false
  defmacro __using__(opts) do
    quote do
      use GenServer
      use AMQP
      # alias StepFlow.Amqp.Connection

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
        hostname = System.get_env("AMQP_HOSTNAME") || Application.get_env(:amqp, :hostname)
        username = System.get_env("AMQP_USERNAME") || Application.get_env(:amqp, :username)
        password = System.get_env("AMQP_PASSWORD") || Application.get_env(:amqp, :password)

        virtual_host =
          System.get_env("AMQP_VHOST") || Application.get_env(:amqp, :virtual_host) || ""

        virtual_host =
          case virtual_host do
            "" -> virtual_host
            _ -> "/" <> virtual_host
          end

        port =
          System.get_env("AMQP_PORT") || Application.get_env(:amqp, :port) ||
            5672
            |> port_format

        url =
          "amqp://" <>
            username <> ":" <> password <> "@" <> hostname <> ":" <> port <> virtual_host

        Logger.warn("#{__MODULE__}: Connecting with url: #{url}")

        case AMQP.Connection.open(url) do
          {:ok, connection} ->
            Process.monitor(connection.pid)

            {:ok, channel} = AMQP.Channel.open(connection)
            queue = unquote(opts).queue

            exchange = AMQP.Exchange.topic(channel, "job_response", [durable: true])

            AMQP.Queue.declare(channel, queue, durable: false)

            Logger.warn("#{__MODULE__}: bind #{queue}")
            AMQP.Queue.bind(channel, queue, "job_response", [routing_key: queue])
            |> IO.inspect
            Logger.warn("#{__MODULE__}: connected to queue #{queue}")

            {:ok, _consumer_tag} = AMQP.Basic.consume(channel, queue)
            {:ok, channel}

          {:error, message} ->
            Logger.error(
              "#{__MODULE__}: unable to connect to: #{url}, reason: #{inspect(message)}"
            )

            # Reconnection loop
            :timer.sleep(10000)
            rabbitmq_connect()
        end
      end
    end
  end
end
