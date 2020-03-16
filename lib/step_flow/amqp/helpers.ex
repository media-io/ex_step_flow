defmodule StepFlow.Amqp.Helpers do
  require Logger

  @moduledoc """
  Helpers for AMQP.
  """

  @doc """
  Get AMQP URL from the configuration or environment variables.
  - `hostname` Setup the hostname of the RabbitMQ service
  - `username` Setup the username of the RabbitMQ service
  - `password` Setup the password of the RabbitMQ service
  - `port` Setup the port of the RabbitMQ service
  - `virtual_host` Setup the virtual host of the RabbitMQ service

  Hardcoded example:
  config :step_flow, StepFlow.Amqp,
    hostname: "example.com",
    port: "5678",
    username: "mediacloudai",
    password: "mediacloudai",
    virtual_host: "media_cloud_ai_dev"

  Environment getter example:
  config :step_flow, StepFlow.Amqp,
    hostname: {:system, "AMQP_HOSTNAME"},
    port: {:system, "AMQP_PORT"},
    username: {:system, "AMQP_USERNAME"},
    password: {:system, "AMQP_PASSWORD"},
    virtual_host: {:system, "AMQP_VIRTUAL_HOST"},
  """
  def get_amqp_connection_url do
    hostname = StepFlow.Configuration.get_var_value(StepFlow.Amqp, :hostname)
    username = StepFlow.Configuration.get_var_value(StepFlow.Amqp, :username)
    password = StepFlow.Configuration.get_var_value(StepFlow.Amqp, :password)
    virtual_host = get_amqp_virtual_host()
    port = get_amqp_port()

    Logger.warn("#{__MODULE__}: Connecting with hostname: #{hostname}")

    url =
      "amqp://" <> username <> ":" <> password <> "@" <> hostname <> ":" <> port <> virtual_host

    Logger.warn("#{__MODULE__}: Connecting with url: #{url}")
    url
  end

  defp get_amqp_port do
    StepFlow.Configuration.get_var_value(StepFlow.Amqp, :port, 5672)
      |> StepFlow.Configuration.to_string
  end

  defp get_amqp_virtual_host do
    StepFlow.Configuration.get_var_value(StepFlow.Amqp, :virtual_host, "")
    |> case do
      "" -> ""
      virtual_host -> "/" <> virtual_host
    end
  end
end
