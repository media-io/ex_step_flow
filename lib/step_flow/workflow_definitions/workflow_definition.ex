defmodule StepFlow.WorkflowDefinitions.WorkflowDefinition do
  @moduledoc """
  The WorkflowDefinition context.
  """

  require Logger

  defstruct(
    identifier: "",
    parameters: []
  )

  def valid?(definition) do
    get_schema()
    |> JsonXema.valid?(definition)
  end

  def validate(definition) do
    get_schema()
    |> JsonXema.validate(definition)
  end

  defp get_schema do
    schema =
      "https://media-cloud.ai/standard/1.1/workflow-definition.schema.json"
      |> load_content()
      |> Jason.decode!()

    :ok = JsonXema.SchemaValidator.validate("http://json-schema.org/draft-07/schema#", schema)

    schema
    |> JsonXema.new()
  end

  defp load_content("http://" <> _ = url) do
    HTTPoison.get!(url)
    |> Map.get(:body)
  end

  defp load_content("https://" <> _ = url) do
    HTTPoison.get!(url)
    |> Map.get(:body)
  end

  defp load_content(source_filename) do
    File.read!(source_filename)
  end

  def get_workflow_definition_directories do
    Application.get_env(:step_flow, StepFlow)
    |> Keyword.get(:workflow_definition)
    |> case do
      {:system, key} ->
        System.get_env(key)
        |> String.split(get_separator())

      key when is_list(key) ->
        key

      key when is_bitstring(key) ->
        [key]

      key ->
        Logger.info("unable to use #{inspect(key)} to list directory")
        []
    end
  end

  defp get_separator do
    if :os.type() |> elem(0) == :unix do
      ":"
    else
      ";"
    end
  end
end
