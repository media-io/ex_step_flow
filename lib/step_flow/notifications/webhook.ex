defmodule StepFlow.Notifications.WebHook do
  @moduledoc """
  Notification step implementation to send HTTP call.
  """

  require Logger
  alias StepFlow.Step.Helpers

  def process(workflow, dates, _step_name, step, _step_id, source_paths) do
    Logger.debug("#{__MODULE__}: Make HTTP call")

    method =
      Helpers.get_value_in_parameters_with_type(step, "method", "string")
      |> List.first() || "POST"

    url =
      Helpers.get_string_or_processed_template_value(workflow, step, dates, source_paths, "url")

    body =
      Helpers.get_string_or_processed_template_value(workflow, step, dates, source_paths, "body")

    headers = get_headers(workflow, step, dates, source_paths)

    Logger.info(
      "#{__MODULE__}: #{method} #{url}, headers: #{inspect(headers)}, body: #{inspect(body)}"
    )

    {:ok, response} = HTTPoison.request(method, url, body, headers)

    if response.status_code == 200 do
      {:ok, response.body}
    else
      {:error,
       "response status code: #{response.status_code} with body: #{inspect(response.body)}"}
    end
  end

  def get_headers(workflow, step, dates, source_paths) do
    Helpers.get_string_or_processed_template_value(
      workflow,
      step,
      dates,
      source_paths,
      "headers",
      "{}"
    )
    |> Jason.decode()
    |> case do
      {:ok, parsed} ->
        Enum.map(parsed, fn {key, value} ->
          {key, value}
        end)

      _ ->
        {:error, "unable to headers"}
    end
  end
end
