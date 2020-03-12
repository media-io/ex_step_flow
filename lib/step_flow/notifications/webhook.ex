defmodule StepFlow.Notifications.WebHook do
  require Logger

  def process(workflow, dates, _step_name, step, _step_id, source_paths) do
    Logger.debug("#{__MODULE__}: Make HTTP call")

    method =
      StepFlow.Step.Helpers.get_value_in_parameters_with_type(step, "method", "string")
      |> List.first || "POST"

    url =
      StepFlow.Step.Helpers.get_value_in_parameters_with_type(step, "url", "string")
      |> List.first
      |> case do
        nil ->
          StepFlow.Step.Helpers.get_value_in_parameters_with_type(step, "url", "template")
          |> List.first
          |> case do
            nil -> ""
            template ->
              template
              |> StepFlow.Step.Helpers.template_process(workflow, step, dates, source_paths)
          end
        url -> url
      end

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

    headers = []
    Logger.info("#{__MODULE__}: #{method} #{url}, headers: #{inspect headers}, body: #{inspect body}")

    {:ok, response} = HTTPoison.request(method, url, body, headers)

    if response.status_code == 200 do
      {:ok, response.body}
    else
      {:error, "response status code: #{response.status_code} with body: #{inspect response.body}"}
    end
  end
end
