defmodule StepFlow.Jobs do
  @moduledoc """
  The Jobs context.
  """

  import Ecto.Query, warn: false
  alias StepFlow.Repo

  alias StepFlow.Jobs.Job
  alias StepFlow.Jobs.Status

  @doc """
  Returns the list of jobs.

  ## Examples

      iex> list_jobs()
      [%Job{}, ...]

  """
  def list_jobs(params \\ %{}) do
    page =
      Map.get(params, "page", 0)
      |> StepFlow.Integer.force()

    size =
      Map.get(params, "size", 10)
      |> StepFlow.Integer.force()

    offset = page * size

    query = from(job in Job)

    query =
      case Map.get(params, "workflow_id") do
        nil ->
          query

        str_workflow_id ->
          workflow_id = String.to_integer(str_workflow_id)
          from(job in query, where: job.workflow_id == ^workflow_id)
      end

    query =
      case Map.get(params, "job_type") do
        nil ->
          query

        job_type ->
          from(job in query, where: job.name == ^job_type)
      end

    query =
      case Map.get(params, "step_id") do
        nil ->
          query

        step_id ->
          from(job in query, where: job.step_id == ^step_id)
      end

    query =
      case Map.get(params, "direct_messaging_queue_name") do
        nil ->
          query

        direct_messaging_queue_name ->
          direct_messaging_queue_name = String.replace(direct_messaging_queue_name, "direct_messaging_", "")

          expected = %{
            id: "direct_messaging_queue_name",
            type: "string",
            value: direct_messaging_queue_name
          } |> Jason.encode!()

          from(job in query, where: fragment("? @> array[?::text]::jsonb[]", job.parameters, ^expected))
      end

    total_query = from(item in query, select: count(item.id))

    total =
      Repo.all(total_query)
      |> List.first()

    query =
      from(
        job in query,
        order_by: [desc: :inserted_at],
        offset: ^offset,
        limit: ^size
      )

    jobs =
      Repo.all(query)
      |> Repo.preload([:status, :progressions, :updates])

    %{
      data: jobs,
      total: total,
      page: page,
      size: size
    }
  end

  @doc """
  Gets a single job.

  Raises `Ecto.NoResultsError` if the Job does not exist.

  ## Examples

      iex> get_job!(123)
      %Job{}

      iex> get_job!(456)
      ** (Ecto.NoResultsError)

  """
  def get_job!(id), do: Repo.get!(Job, id)

  @doc """
  Gets a single job.

  ## Examples

      iex> get_job(123)
      %Job{}

      iex> get_job(456)
      nil

  """
  def get_job(id), do: Repo.get(Job, id)

  @doc """
  Gets a single job by workflow ID and step ID

  ## Examples

      iex> get_job(123)
      %Job{}

      iex> get_job(456)
      nil

  """
  def get_by!(%{"workflow_id" => workflow_id, "step_id" => step_id}) do
    Repo.get_by!(Job, workflow_id: workflow_id, step_id: step_id)
  end

  @doc """
  Gets a single job by workflow ID and step ID

  ## Examples

      iex> get_job(123)
      %Job{}

      iex> get_job(456)
      nil

  """
  def get_by(%{"workflow_id" => workflow_id, "step_id" => step_id}) do
    Repo.get_by(Job, workflow_id: workflow_id, step_id: step_id)
  end

  @doc """
  Gets a single job with its related status.

  Raises `Ecto.NoResultsError` if the Job does not exist.

  ## Examples

      iex> get_job_with_status!(123)
      %Job{}

      iex> get_job!(456)
      ** (Ecto.NoResultsError)

  """
  def get_job_with_status!(id) do
    get_job!(id)
    |> Repo.preload([:status, :progressions, :updates])
  end

  @doc """
  Creates a job.

  ## Examples

      iex> create_job(%{field: value})
      {:ok, %Job{}}

      iex> create_job(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_job(attrs \\ %{}) do
    %Job{}
    |> Job.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a job with a skipped status.

  ## Examples

      iex> create_skipped_job(workflow, 1, "download_http")
      {:ok, "skipped"}

  """
  def create_skipped_job(workflow, step_id, action) do
    job_params = %{
      name: action,
      step_id: step_id,
      workflow_id: workflow.id,
      parameters: []
    }

    {:ok, job} = create_job(job_params)
    Status.set_job_status(job.id, :skipped)
    {:ok, "skipped"}
  end

  @doc """
  Creates a job with an error status.

  ## Examples

      iex> create_error_job(workflow, step_id, "download_http", "unsupported step")
      {:ok, "created"}

  """
  def create_error_job(workflow, step_id, action, description) do
    job_params = %{
      name: action,
      step_id: step_id,
      workflow_id: workflow.id,
      parameters: []
    }

    {:ok, job} = create_job(job_params)
    Status.set_job_status(job.id, :error, %{message: description})
    {:ok, "created"}
  end

  @doc """
  Creates a job with a completed status.

  ## Examples

      iex> create_completed_job(workflow, step_id, "webhook_notification")
      {:ok, "completed"}

  """
  def create_completed_job(workflow, step_id, action) do
    job_params = %{
      name: action,
      step_id: step_id,
      workflow_id: workflow.id,
      parameters: []
    }

    {:ok, job} = create_job(job_params)
    Status.set_job_status(job.id, :completed)
    {:ok, "completed"}
  end

  @doc """
  Set skipped status to all queued jobs.

  ## Examples

      iex> skip_jobs(workflow, step_id, "download_http")
      :ok

  """
  def skip_jobs(workflow, step_id, action) do
    list_jobs(%{
      name: action,
      step_id: step_id,
      workflow_id: workflow.id
    })

    # Create dedicated method
    |> Map.get(:data)
    |> Enum.filter(fn job ->
      case job.status do
        [%{state: state}] -> state != "queued"
        _ -> false
      end
    end)
    |> Enum.each(fn job ->
      Status.set_job_status(job.id, :skipped)
    end)
  end

  @doc """
  Updates a job.

  ## Examples

      iex> update_job(job, %{field: new_value})
      {:ok, %Job{}}

      iex> update_job(job, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_job(%Job{} = job, attrs) do
    job
    |> Job.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Job.

  ## Examples

      iex> delete_job(job)
      {:ok, %Job{}}

      iex> delete_job(job)
      {:error, %Ecto.Changeset{}}

  """
  def delete_job(%Job{} = job) do
    Repo.delete(job)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job changes.

  ## Examples

      iex> change_job(job)
      %Ecto.Changeset{source: %Job{}}

  """
  def change_job(%Job{} = job) do
    Job.changeset(job, %{})
  end

  @doc """
  Returns a formatted message for AMQP orders.

  ## Examples

      iex> get_message(job)
      %{job_id: 123, parameters: [{id: "input", type: "string", value: "/path/to/input"}]}

  """
  def get_message(%Job{} = job) do
    %{
      job_id: job.id,
      parameters: job.parameters
    }
  end
end
