defmodule StepFlow.Notifications.Slack do
  @moduledoc """
  Notification step implementation to send messages on Slack channel
  """

  alias StepFlow.Step.Helpers

  def process(workflow, dates, _step_name, step, _step_id, source_paths) do
    channel =
      Helpers.get_value_in_parameters_with_type(step, "channel", "string")
      |> List.first() || "general"

    body =
      Helpers.get_string_or_processed_template_value(workflow, step, dates, source_paths, "body")

    if StepFlow.Configuration.get_slack_token() != nil do
      send(:step_flow_slack_bot, {:message, body, StepFlow.Configuration.format_channel(channel)})

      {:ok, "sended"}
    else
      {:error, "missing slack configuration"}
    end
  end
end
