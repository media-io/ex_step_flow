defmodule StepFlow.Amqp.CommonConsumer do
  @moduledoc """
  Definition of a Common Consumer of RabbitMQ queue.

  To implement a consumer,

  ```elixir
  defmodule MyModule do
    use StepFlow.Amqp.CommonConsumer, %{
      queue: "name_of_the_rabbit_mq_queue",
      consumer: &MyModule.consume/4
    }

    def consume(channel, tag, redelivered, payload) do
      ...
      Basic.ack(channel, tag)
    end
  end
  ```

  """

  @doc false
  defmacro __using__(opts) do
    quote do
      use GenServer
      use AMQP

      alias StepFlow.Amqp.CommonEmitter
      alias StepFlow.Amqp.Helpers

      @doc false
      def start_link do
        GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
      end

      @doc false
      def init(:ok) do
        rabbitmq_connect()
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
            {:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered} = headers},
            channel
          ) do
        queue = unquote(opts).queue

        data =
          payload
          |> Jason.decode!()

        Logger.info("#{__MODULE__}: receive message on queue: #{queue}")

        max_retry_to_timeout =
          StepFlow.Configuration.get_var_value(StepFlow.Amqp, :max_retry_to_timeout, 10)

        Logger.debug("#{__MODULE__} #{inspect(headers)}")

        max_retry_reached =
          with headers when headers != :undefined <- Map.get(headers, :headers),
               {"x-death", :array, death} <- List.keyfind(headers, "x-death", 0),
               {:table, table} <- List.first(death),
               {"count", :long, count} <- List.keyfind(table, "count", 0) do
            count > max_retry_to_timeout
          else
            _ -> false
          end

        if max_retry_reached do
          Logger.warn("#{__MODULE__}: timeout message sent to queue: #{queue}_timeout")
          CommonEmitter.publish(queue <> "_timeout", payload)
          AMQP.Basic.ack(channel, tag)
        else
          unquote(opts).consumer.(channel, tag, redelivered, data)
        end

        {:noreply, channel}
      end

      def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
        {:ok, chan} = rabbitmq_connect()
        # {:noreply, :ok}
      end

      def terminate(_reason, state) do
        AMQP.Connection.close(state.conn)
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

        if Map.has_key?(unquote(opts), :prefetch_count) do
          :ok = AMQP.Basic.qos(channel, prefetch_count: unquote(opts).prefetch_count)
        end

        AMQP.Queue.declare(channel, "job_response_not_found", durable: true)
        AMQP.Queue.declare(channel, queue <> "_timeout", durable: true)

        exchange =
          AMQP.Exchange.topic(channel, "job_response",
            durable: true,
            arguments: [{"alternate-exchange", :longstr, "job_response_not_found"}]
          )

        AMQP.Queue.declare(channel, "direct_message_not_found", durable: true)
        AMQP.Queue.declare(channel, queue <> "_timeout", durable: true)

        exchange =
          AMQP.Exchange.declare(channel, "direct_message",
            :headers,
            durable: true,
            arguments: [{"alternate-exchange", :longstr, "direct_message_not_found"}]
          )

        exchange = AMQP.Exchange.fanout(channel, "job_response_delayed", durable: true)

        {:ok, job_response_delayed_queue} =
          AMQP.Queue.declare(channel, "job_response_delayed",
            arguments: [
              {"x-message-ttl", :short, 5000},
              {"x-dead-letter-exchange", :longstr, ""}
            ]
          )

        AMQP.Queue.bind(channel, "job_response_delayed", "job_response_delayed", routing_key: "*")

        AMQP.Queue.declare(channel, queue,
          durable: true,
          arguments: [
            {"x-dead-letter-exchange", :longstr, "job_response_delayed"},
            {"x-dead-letter-routing-key", :longstr, queue}
          ]
        )

        Logger.warn("#{__MODULE__}: bind #{queue}")
        AMQP.Queue.bind(channel, queue, "job_response", routing_key: queue)

        Logger.warn("#{__MODULE__}: connected to queue #{queue}")

        {:ok, _consumer_tag} = AMQP.Basic.consume(channel, queue)
        {:ok, channel}
      end
    end
  end
end
