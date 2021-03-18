defmodule StepFlow.Workflows do
  @moduledoc """
  The Workflows context.
  """

  import Ecto.Query, warn: false

  alias StepFlow.Artifacts.Artifact
  alias StepFlow.Jobs
  alias StepFlow.Jobs.Status
  alias StepFlow.Progressions.Progression
  alias StepFlow.Repo
  alias StepFlow.Workflows.Workflow

  require Logger

  @doc """
  Returns the list of workflows.

  ## Examples

      iex> list_workflows()
      [%Workflow{}, ...]

  """
  def list_workflows(params \\ %{}) do
    page =
      Map.get(params, "page", 0)
      |> StepFlow.Integer.force()

    size =
      Map.get(params, "size", 10)
      |> StepFlow.Integer.force()

    offset = page * size

    query =
      case Map.get(params, "rights") do
        nil ->
          from(workflow in Workflow)

        user_rights ->
          from(
            workflow in Workflow,
            join: rights in assoc(workflow, :rights),
            where: rights.action == "view",
            where: fragment("?::varchar[] && ?::varchar[]", rights.groups, ^user_rights)
          )
      end

    query =
      from(workflow in subquery(query))
      |> filter_query(params, :video_id)
      |> filter_query(params, :identifier)
      |> filter_query(params, :version_major)
      |> filter_query(params, :version_minor)
      |> filter_query(params, :version_micro)
      |> date_before_filter_query(params, :before_date)
      |> date_after_filter_query(params, :after_date)

    query = filter_status(query, params)

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
      |> Repo.preload([:jobs, :artifacts, :rights])
      |> preload_workflows

    %{
      data: workflows,
      total: total,
      page: page,
      size: size
    }
  end

  defp get_status(status, completed_status) do
    if status != nil do
      if Status.state_enum_label(:completed) in status do
        if status == completed_status do
          :completed
        else
          nil
        end
      else
        if Status.state_enum_label(:error) in status do
          :error
        else
          :processing
        end
      end
    else
      nil
    end
  end

  defp filter_status(query, params) do
    status = Map.get(params, "state")

    completed_status = [
      Status.state_enum_label(:completed)
    ]

    case get_status(status, completed_status) do
      nil ->
        query

      :completed ->
        from(
          workflow in query,
          left_join: artifact in assoc(workflow, :artifacts),
          where: not is_nil(artifact.id)
        )

      :error ->
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

      :processing ->
        from(
          workflow in query,
          join: jobs in assoc(workflow, :jobs),
          join: status in assoc(jobs, :status),
          where: status.state in ^status
        )
    end
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
    |> Repo.preload([:jobs, :artifacts, :rights])
    |> preload_workflow
  end

  defp preload_workflow(workflow) do
    jobs = Repo.preload(workflow.jobs, [:status, :progressions])

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

  def get_step_status(steps, workflow_jobs, result \\ [])
  def get_step_status([], _workflow_jobs, result), do: result
  def get_step_status(nil, _workflow_jobs, result), do: result

  def get_step_status([step | steps], workflow_jobs, result) do
    name = StepFlow.Map.get_by_key_or_atom(step, :name)
    step_id = StepFlow.Map.get_by_key_or_atom(step, :id)

    jobs =
      workflow_jobs
      |> Enum.filter(fn job -> job.name == name && job.step_id == step_id end)

    completed = count_status(jobs, :completed)
    errors = count_status(jobs, :error)
    skipped = count_status(jobs, :skipped)
    processing = count_status(jobs, :processing)
    queued = count_status(jobs, :queued)

    job_status = %{
      total: length(jobs),
      completed: completed,
      errors: errors,
      processing: processing,
      queued: queued,
      skipped: skipped
    }

    status =
      cond do
        errors > 0 -> :error
        processing > 0 -> :processing
        queued > 0 -> :processing
        skipped > 0 -> :skipped
        completed > 0 -> :completed
        # TO DO: change this case into to_start as not started yet
        true -> :queued
      end

    step =
      step
      |> Map.put(:status, status)
      |> Map.put(:jobs, job_status)

    result = List.insert_at(result, -1, step)
    get_step_status(steps, workflow_jobs, result)
  end

  def get_step_definition(job) do
    job = Repo.preload(job, workflow: [:jobs])

    step =
      Enum.filter(job.workflow.steps, fn step ->
        Map.get(step, "id") == job.step_id
      end)
      |> List.first()

    %{step: step, workflow: job.workflow}
  end

  defp count_status(jobs, status, count \\ 0)
  defp count_status([], _status, count), do: count

  defp count_status([job | jobs], status, count) do
    count_completed =
      job.status
      |> Enum.filter(fn s -> s.state == :completed end)
      |> length

    # A job with at least one status.state at :completed is considered :completed
    count =
      if count_completed >= 1 do
        if status == :completed do
          count + 1
        else
          count
        end
      else
        case status do
          :processing ->
            count_processing(job, count)

          :error ->
            count_error(job, count)

          :skipped ->
            count_skipped(job, count)

          :queued ->
            count_queued(job, count)

          :completed ->
            count

          _ ->
            raise RuntimeError
            Logger.error("unereachable")
            count
        end
      end

    count_status(jobs, status, count)
  end

  defp count_processing(job, count) do
    if job.progressions == [] do
      count
    else
      last_progression =
        job.progressions
        |> Progression.get_last_progression()

      last_status =
        job.status
        |> Status.get_last_status()

      cond do
        last_status == nil -> count + 1
        last_progression.updated_at > last_status.updated_at -> count + 1
        true -> count
      end
    end
  end

  defp count_error(job, count) do
    if Enum.map(job.status, fn s -> s.state end)
       |> List.last()
       |> Kernel.==(:error) do
      count + 1
    else
      count
    end
  end

  defp count_skipped(job, count) do
    if Enum.map(job.status, fn s -> s.state end)
       |> List.last()
       |> Kernel.==(:skipped) do
      count + 1
    else
      count
    end
  end

  defp count_queued(job, count) do
    case {Enum.map(job.status, fn s -> s.state end) |> List.last(), job.progressions} do
      {nil, []} ->
        count + 1

      {nil, _} ->
        count

      {:retrying, []} ->
        count + 1

      {:retrying, _} ->
        last_progression = job.progressions |> Progression.get_last_progression()
        last_status = job.status |> Status.get_last_status()

        if last_progression.updated_at > last_status.updated_at do
          count
        else
          count + 1
        end

      {_state, _} ->
        count
    end
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

  def notification_from_job(job_id, description \\ nil) do
    job = Jobs.get_job!(job_id)
    topic = "update_workflow_" <> Integer.to_string(job.workflow_id)
    channel = StepFlow.Configuration.get_slack_channel()

    if StepFlow.Configuration.get_slack_token() != nil and description != nil and channel != nil do
      exposed_domain_name = StepFlow.Configuration.get_exposed_domain_name()

      send(
        :step_flow_slack_bot,
        {:message,
         "Error for job #{job.name} ##{job_id} <#{exposed_domain_name}/workflows/#{
           job.workflow_id
         } |Open Workflow>\n```#{description}```", channel}
      )
    end

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

  def get_completed_statistics(scale, delta) do
    query =
      from(
        workflow in Workflow,
        inner_join:
          artifacts in subquery(
            from(
              artifacts in Artifact,
              where:
                artifacts.inserted_at > datetime_add(^NaiveDateTime.utc_now(), ^delta, ^scale),
              group_by: artifacts.workflow_id,
              select: %{
                workflow_id: artifacts.workflow_id,
                inserted_at: max(artifacts.inserted_at)
              }
            )
          ),
        on: workflow.id == artifacts.workflow_id,
        group_by: workflow.identifier,
        select: %{
          count: count(),
          duration:
            fragment(
              "EXTRACT(EPOCH FROM (SELECT avg(? - ?)))",
              artifacts.inserted_at,
              workflow.inserted_at
            ),
          identifier: workflow.identifier
        }
      )

    Repo.all(query)
  end

  def get_error_statistics(scale, delta) do
    query =
      from(
        job_status in Status,
        where:
          job_status.inserted_at > datetime_add(^NaiveDateTime.utc_now(), ^delta, ^scale) and
            job_status.state == :error,
        inner_join: job in Jobs.Job,
        on: job.id == job_status.job_id,
        left_join: workflow in Workflow,
        on: workflow.id == job.workflow_id,
        group_by: workflow.identifier,
        select: %{
          count: count(),
          identifier: workflow.identifier
        }
      )

    Repo.all(query)
  end

  def get_creation_statistics(scale, delta) do
    query =
      from(
        workflow in Workflow,
        where: workflow.inserted_at > datetime_add(^NaiveDateTime.utc_now(), ^delta, ^scale),
        group_by: workflow.identifier,
        select: %{
          count: count(),
          identifier: workflow.identifier
        }
      )

    Repo.all(query)
  end
end
