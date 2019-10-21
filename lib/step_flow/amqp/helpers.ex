defmodule StepFlow.Amqp.Helpers do
  require Logger
  @moduledoc """
  Helpers for AMQP.
  """

  def get_amqp_connection_url do
    hostname = System.get_env("AMQP_HOSTNAME") || Application.get_env(:amqp, :hostname)
    username = System.get_env("AMQP_USERNAME") || Application.get_env(:amqp, :username)
    password = System.get_env("AMQP_PASSWORD") || Application.get_env(:amqp, :password)

    virtual_host = get_amqp_virtual_host()
    port = get_amqp_port()

    Logger.warn("#{__MODULE__}: Connecting with hostname: #{hostname}")

    url =
      "amqp://" <> username <> ":" <> password <> "@" <> hostname <> ":" <> port <> virtual_host

    Logger.warn("#{__MODULE__}: Connecting with url: #{url}")
    url
  end

  defp get_amqp_port do
    System.get_env("AMQP_PORT") || Application.get_env(:amqp, :port) || 5672
    |> port_format
  end

  defp get_amqp_virtual_host do
    virtual_host = System.get_env("AMQP_VHOST") || Application.get_env(:amqp, :virtual_host) || ""

    case virtual_host do
      "" -> ""
      _ -> "/" <> virtual_host
    end
  end

  defp port_format(port) when is_integer(port) do
    Integer.to_string(port)
  end

  defp port_format(port) do
    port
  end
end
