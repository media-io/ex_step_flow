defmodule StepFlow.WorkflowDefinitions.WorkflowDefinition do
  @moduledoc """
  The WorkflowDefinition context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  require Logger
  alias StepFlow.Repo
  alias StepFlow.WorkflowDefinitions.ExternalLoader
  alias StepFlow.WorkflowDefinitions.WorkflowDefinition

  schema "step_flow_workflow_definition" do
    field(:identifier, :string)
    field(:label, :string, default: "")
    field(:icon, :string, default: "")
    field(:version_major, :integer)
    field(:version_minor, :integer)
    field(:version_micro, :integer)
    field(:tags, {:array, :string}, default: [])
    field(:steps, {:array, :map}, default: [])
    field(:start_parameters, {:array, :map}, default: [])
    field(:parameters, {:array, :map}, default: [])
    timestamps()
  end

  @doc false
  def changeset(%WorkflowDefinition{} = workflow_definition, attrs) do
    workflow_definition
    |> cast(attrs, [
      :identifier,
      :label,
      :icon,
      :version_major,
      :version_minor,
      :version_micro,
      :tags,
      :steps,
      :start_parameters,
      :parameters
    ])
    |> validate_required([
      :identifier,
      :version_major,
      :version_minor,
      :version_micro
    ])
    |> unique_constraint(
      :identifier,
      name: :workflow_identifier_index
    )
  end

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
      "https://media-cloud.ai/standard/1.7/workflow-definition.schema.json"
      |> load_content()
      |> Jason.decode!()

    :ok = JsonXema.SchemaValidator.validate("http://json-schema.org/draft-07/schema#", schema)

    JsonXema.new(schema, loader: ExternalLoader)
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

  def load_workflows do
    get_workflow_definition_directories()
    |> Enum.map(fn directory ->
      list_workflow_definitions_for_a_directory(directory)
    end)
    |> List.flatten()
  end

  def load_workflows_in_database do
    get_workflow_definition_directories()
    |> Enum.map(fn directory ->
      list_workflow_definitions_for_a_directory(directory)
    end)
    |> List.flatten()
    |> Enum.each(fn workflow_definition ->
      %WorkflowDefinition{}
      |> WorkflowDefinition.changeset(workflow_definition)
      |> Repo.insert()
    end)
  end

  defp get_separator do
    if :os.type() |> elem(0) == :unix do
      ":"
    else
      ";"
    end
  end

  defp list_workflow_definitions_for_a_directory(directory) do
    File.ls!(directory)
    |> Enum.filter(fn filename ->
      String.ends_with?(filename, ".json")
    end)
    |> Enum.map(fn filename ->
      Path.join(directory, filename)
      |> File.read!()
      |> Jason.decode!()
    end)
    |> Enum.filter(fn workflow_definition ->
      if valid?(workflow_definition) do
        true
      else
        errors = validate(workflow_definition)
        Logger.error("Workflow definition not valid: #{inspect(errors)}")
        false
      end
    end)
  end
end
