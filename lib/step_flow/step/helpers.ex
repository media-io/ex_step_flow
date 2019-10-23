defmodule StepFlow.Step.Helpers do
  @moduledoc """
  The Helper Step context.
  """

  @doc """
  Retrieve a value on an Object, filtered by the key
  """
  def get_value_in_parameters(object, key) do
    StepFlow.Map.get_by_key_or_atom(object, :parameters, [])
    |> Enum.filter(fn param ->
      StepFlow.Map.get_by_key_or_atom(param, :id) == key
    end)
    |> Enum.map(fn param ->
      StepFlow.Map.get_by_key_or_atom(param, :value)
    end)
  end

  def get_jobs_destination_paths(jobs) do
    jobs
    |> Enum.map(fn job ->
      get_job_destination_paths(job)
    end)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.filter(fn path -> !is_nil(path) end)
  end

  def get_job_destination_paths(job) do
    destination_path = get_value_in_parameters(job, "destination_path")
    destination_paths = get_value_in_parameters(job, "destination_paths")

    destination_path ++ destination_paths
  end

  def filter_path_list(source_paths, []), do: source_paths

  def filter_path_list(source_paths, [filter | filters]) do
    new_source_paths =
      case filter do
        %{ends_with: ends_with} ->
          Enum.filter(source_paths, fn path -> String.ends_with?(path, ends_with) end)

        %{"ends_with" => ends_with} ->
          Enum.filter(source_paths, fn path -> String.ends_with?(path, ends_with) end)
      end

    filter_path_list(new_source_paths, filters)
  end

  def get_step_requirements(jobs, step) do
    %{paths: get_required_paths(jobs, step)}
  end

  def get_required_paths(jobs, step) do
    required_ids = StepFlow.Map.get_by_key_or_atom(step, :required, [])

    jobs
    |> Enum.filter(fn job -> job.step_id in required_ids end)
    |> get_jobs_destination_paths
  end

  def new_required_paths(path) do
    add_required_paths(%{}, path)
  end

  def add_required_paths(requirements, paths) when is_list(paths) do
    Map.update(requirements, :paths, paths, fn cur_paths ->
      Enum.concat(cur_paths, paths)
      |> Enum.uniq()
    end)
  end

  def add_required_paths(requirements, path) do
    paths =
      Map.get(requirements, :paths, [])
      |> List.insert_at(-1, path)

    add_required_paths(requirements, paths)
  end
end
