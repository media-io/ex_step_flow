defmodule StepFlow.Notifications.Notification do
  @moduledoc """
  Notification implementation with various services.
  - WebHook to make HTTP call to external APIs
  - Slack to post a message on a channel
  """

  alias StepFlow.Jobs

  def process(workflow, dates, step_name, step, step_id, source_paths) do

    caller = StepFlow.Step.Helpers.get_value_in_parameters_with_type(step, "service", "string")
      |> List.first
      |> get_class_implementation()

    case caller.(workflow, dates, step_name, step, step_id, source_paths) do
      {:ok, _response} -> Jobs.create_completed_job(workflow, step_id, step_name)
      {:error, error_message} -> Jobs.create_error_job(workflow, step_id, step_name, error_message)
    end    
  end

  defp get_class_implementation("slack"), do: &StepFlow.Notifications.Slack.process/6
  defp get_class_implementation(_service_identifier), do: &StepFlow.Notifications.WebHook.process/6
end
