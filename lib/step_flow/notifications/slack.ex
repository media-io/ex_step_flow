defmodule StepFlow.Notifications.Slack do

  def process(workflow, dates, _step_name, step, _step_id, source_paths) do

    channel =
      StepFlow.Step.Helpers.get_value_in_parameters_with_type(step, "channel", "string")
      |> List.first || "general"

    body =
      StepFlow.Step.Helpers.get_value_in_parameters_with_type(step, "body", "string")
      |> List.first
      |> case do
        nil ->
          StepFlow.Step.Helpers.get_value_in_parameters_with_type(step, "body", "template")
          |> List.first
          |> case do
            nil -> ""
            template ->
              template
              |> StepFlow.Step.Helpers.template_process(workflow, step, dates, source_paths)
          end
        body -> body
      end

    if StepFlow.Configuration.get_slack_token() != nil do
      send(:step_flow_slack_bot, {:message, body, StepFlow.Configuration.format_channel(channel)})

      {:ok, "sended"}
    else
      {:error, "missing slack configuration"}
    end
  end
end
