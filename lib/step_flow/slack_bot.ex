defmodule StepFlow.SlackBot do
  @moduledoc """
  Bot connected to Slack if the token is provided.
  It allow to send notifications to channel.
  """

  use Slack
  require Logger

  def handle_connect(slack, state) do
    Logger.error("Connected as #{slack.me.name}")
    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    send_message(text, channel, slack)
    {:ok, state}
  end

  def handle_info(_, _, state), do: {:ok, state}
end
