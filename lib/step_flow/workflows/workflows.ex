defmodule StepFlow.Workflows do
  @moduledoc """
  The Workflows context.
  """

  import Ecto.Query, warn: false

  alias StepFlow.Jobs
  alias StepFlow.Jobs.Status
  alias StepFlow.Repo
  alias StepFlow.Workflows.Workflow

  @doc """
  Returns the list of workflows.

  ## Examples

      iex> list_workflows()
      [%Workflow{}, ...]

  """
  def list_workflows(params \\ %{}) do
    page =
      Map.get(params, "page", 0)
      |> StepFlow.Integer.force

    size =
      Map.get(params, "size", 10)
      |> StepFlow.Integer.force

    offset = page * size

    query =
      from(workflow in Workflow)
      |> filter_query(params, :video_id)
      |> filter_query(params, :identifier)
      |> filter_query(params, :version_major)
      |> filter_query(params, :version_minor)
      |> filter_query(params, :version_micro)
      |> date_before_filter_query(params, :before_date)
      |> date_after_filter_query(params, :after_date)

    status = Map.get(params, "state")

    completed_status = ["completed"]

    query =
      if status != nil do
        if "completed" in status do
          if status == completed_status do
            from(
              workflow in query,
              left_join: artifact in assoc(workflow, :artifacts),
              where: not is_nil(artifact.id)
            )
          else
            query
          end
        else
          if "error" in status do
            completed_jobs_to_exclude =
              from(
                workflow in query,
                join: job in assoc(workflow, :jobs),
                join: status in assoc(job, :status),
                where: status.state in ^completed_status,
                group_by: workflow.id
              )

            from(
              workflow in query,
              join: job in assoc(workflow, :jobs),
              join: status in assoc(job, :status),
              where: status.state in ^status,
              group_by: workflow.id,
              except: ^completed_jobs_to_exclude
            )
          else
            from(
              workflow in query,
              join: jobs in assoc(workflow, :jobs),
              join: status in assoc(jobs, :status),
              where: status.state in ^status
            )
          end
        end
      else
        query
      end

    query =
      case StepFlow.Map.get_by_key_or_atom(params, :ids) do
        nil ->
          query

        identifiers ->
          from(workflow in query, where: workflow.id in ^identifiers)
      end

    query =
      case StepFlow.Map.get_by_key_or_atom(params, :workflow_ids) do
        nil ->
          query

        workflow_ids ->
          from(
            workflow in query,
            where: workflow.identifier in ^workflow_ids
          )
      end

    total_query = from(item in subquery(query), select: count(item.id))

    total =
      Repo.all(total_query)
      |> List.first()

    query =
      from(
        workflow in subquery(query),
        order_by: [desc: :inserted_at],
        offset: ^offset,
        limit: ^size
      )

    workflows =
      Repo.all(query)
      |> Repo.preload([:jobs, :artifacts])
      |> preload_workflows

    %{
      data: workflows,
      total: total,
      page: page,
      size: size
    }
  end

  defp filter_query(query, params, key) do
    case StepFlow.Map.get_by_key_or_atom(params, key) do
      nil ->
        query

      value ->
        from(workflow in query, where: field(workflow, ^key) == ^value)
    end
  end

  defp date_before_filter_query(query, params, key) do
    case StepFlow.Map.get_by_key_or_atom(params, key) do
      nil ->
        query

      date_value ->
        date = Date.from_iso8601!(date_value)
        from(workflow in query, where: fragment("?::date", workflow.inserted_at) <= ^date)
    end
  end

  defp date_after_filter_query(query, params, key) do
    case StepFlow.Map.get_by_key_or_atom(params, key) do
      nil ->
        query

      date_value ->
        date = Date.from_iso8601!(date_value)
        from(workflow in query, where: fragment("?::date", workflow.inserted_at) >= ^date)
    end
  end

  @doc """
  Gets a single workflows.

  Raises `Ecto.NoResultsError` if the Workflow does not exist.

  ## Examples

      iex> get_workflows!(123)
      %Workflow{}

      iex> get_workflows!(456)
      ** (Ecto.NoResultsError)

  """
  def get_workflow!(id) do
    Repo.get!(Workflow, id)
    |> Repo.preload([:jobs, :artifacts])
    |> preload_workflow
  end

  defp preload_workflow(workflow) do
    jobs = Repo.preload(workflow.jobs, :status)

    steps =
      workflow
      |> Map.get(:steps)
      |> get_step_status(jobs)

    workflow
    |> Map.put(:steps, steps)
    |> Map.put(:jobs, jobs)
  end

  defp preload_workflows(workflows, result \\ [])
  defp preload_workflows([], result), do: result

  defp preload_workflows([workflow | workflows], result) do
    result = List.insert_at(result, -1, workflow |> preload_workflow)
    preload_workflows(workflows, result)
  end

  defp get_step_status(steps, workflow_jobs, result \\ [])
  defp get_step_status([], _workflow_jobs, result), do: result
  defp get_step_status(nil, _workflow_jobs, result), do: result

  defp get_step_status([step | steps], workflow_jobs, result) do
    name = Map.get(step, "name")
    step_id = Map.get(step, "id")

    jobs =
      workflow_jobs
      |> Enum.filter(fn job -> job.name == name && job.step_id == step_id end)

    completed = count_status(jobs, "completed")
    errors = count_status(jobs, "error")
    skipped = count_status(jobs, "skipped")
    queued = count_queued_status(jobs)

    job_status = %{
      total: length(jobs),
      completed: completed,
      errors: errors,
      queued: queued,
      skipped: skipped
    }

    status =
      cond do
        errors > 0 -> "error"
        queued > 0 -> "processing"
        skipped > 0 -> "skipped"
        completed > 0 -> "completed"
        true -> "queued"
      end

    step =
      step
      |> Map.put(:status, status)
      |> Map.put(:jobs, job_status)

    result = List.insert_at(result, -1, step)
    get_step_status(steps, workflow_jobs, result)
  end

  defp count_status(jobs, status, count \\ 0)
  defp count_status([], _status, count), do: count

  defp count_status([job | jobs], status, count) do
    count_completed =
      job.status
      |> Enum.filter(fn s -> s.state == "completed" end)
      |> length

    count =
      if count_completed >= 1 do
        if status == "completed" do
          count + 1
        else
          count
        end
      else
        Enum.filter(job.status, fn s -> s.state == status end)
        |> length
        |> case do
          0 ->
            count

          _ ->
            count + 1
        end
      end

    count_status(jobs, status, count)
  end

  defp count_queued_status(jobs, count \\ 0)
  defp count_queued_status([], count), do: count

  defp count_queued_status([job | jobs], count) do
    count =
      case Enum.map(job.status, fn s -> s.state end) |> List.last() do
        nil -> count + 1
        _state -> count
      end

    count_queued_status(jobs, count)
  end

  @doc """
  Creates a workflow.

  ## Examples

      iex> create_workflow(%{field: value})
      {:ok, %Workflow{}}

      iex> create_workflow(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_workflow(attrs \\ %{}) do
    %Workflow{}
    |> Workflow.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a workflow.

  ## Examples

      iex> update_workflow(workflow, %{field: new_value})
      {:ok, %Workflow{}}

      iex> update_workflow(workflow, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_workflow(%Workflow{} = workflow, attrs) do
    workflow
    |> Workflow.changeset(attrs)
    |> Repo.update()
  end

  def notification_from_job(job_id) do
    job = Jobs.get_job!(job_id)
    topic = "update_workflow_" <> Integer.to_string(job.workflow_id)

    StepFlow.Notification.send(topic, %{workflow_id: job.workflow_id})
  end

  @doc """
  Deletes a Workflow.

  ## Examples

      iex> delete_workflow(workflow)
      {:ok, %Workflow{}}

      iex> delete_workflow(workflow)
      {:error, %Ecto.Changeset{}}

  """
  def delete_workflow(%Workflow{} = workflow) do
    Repo.delete(workflow)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workflow changes.

  ## Examples

      iex> change_workflow(workflow)
      %Ecto.Changeset{source: %Workflow{}}

  """
  def change_workflow(%Workflow{} = workflow) do
    Workflow.changeset(workflow, %{})
  end

  def jobs_without_status?(workflow_id, status \\ ["completed", "skipped"]) do
    query_count_jobs =
      from(
        workflow in Workflow,
        where: workflow.id == ^workflow_id,
        join: jobs in assoc(workflow, :jobs),
        select: count(jobs.id)
      )

    query_count_state =
      from(
        workflow in Workflow,
        where: workflow.id == ^workflow_id,
        join: jobs in assoc(workflow, :jobs),
        join: status in assoc(jobs, :status),
        where: status.state in ^status,
        select: count(status.id)
      )

    total =
      Repo.all(query_count_jobs)
      |> List.first()

    researched =
      Repo.all(query_count_state)
      |> List.first()

    researched >= total
  end

  def get_workflow_history(%{scale: scale}) do
    Enum.map(
      0..49,
      fn index ->
        %{
          total: query_total(scale, -index, -index - 1),
          rosetta:
            query_by_identifier(scale, -index, -index - 1, "FranceTV Studio Ingest Rosetta"),
          ingest_rdf:
            query_by_identifier(scale, -index, -index - 1, "FranceTélévisions Rdf Ingest"),
          ingest_dash:
            query_by_identifier(scale, -index, -index - 1, "FranceTélévisions Dash Ingest"),
          process_acs: query_by_identifier(scale, -index, -index - 1, "FranceTélévisions ACS"),
          process_acs_standalone:
            query_by_identifier(scale, -index, -index - 1, "FranceTélévisions ACS (standalone)"),
          errors: query_by_status(scale, -index, -index - 1, "error")
        }
      end
    )
  end

  defp query_total(scale, delta_min, delta_max) do
    Repo.aggregate(
      from(
        workflow in Workflow,
        where:
          workflow.inserted_at > datetime_add(^NaiveDateTime.utc_now(), ^delta_max, ^scale) and
            workflow.inserted_at < datetime_add(^NaiveDateTime.utc_now(), ^delta_min, ^scale)
      ),
      :count,
      :id
    )
  end

  defp query_by_identifier(scale, delta_min, delta_max, identifier) do
    Repo.aggregate(
      from(
        workflow in Workflow,
        where:
          workflow.identifier == ^identifier and
            workflow.inserted_at > datetime_add(^NaiveDateTime.utc_now(), ^delta_max, ^scale) and
            workflow.inserted_at < datetime_add(^NaiveDateTime.utc_now(), ^delta_min, ^scale)
      ),
      :count,
      :id
    )
  end

  defp query_by_status(scale, delta_min, delta_max, status) do
    Repo.aggregate(
      from(
        status in Status,
        where:
          status.state == ^status and
            status.inserted_at > datetime_add(^NaiveDateTime.utc_now(), ^delta_max, ^scale) and
            status.inserted_at < datetime_add(^NaiveDateTime.utc_now(), ^delta_min, ^scale)
      ),
      :count,
      :id
    )
  end
end
