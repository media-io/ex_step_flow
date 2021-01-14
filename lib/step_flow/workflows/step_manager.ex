defmodule StepFlow.Workflows.StepManager do
  @moduledoc """
  The Step Manager context.
  """

  require Logger

  use GenServer
  alias StepFlow.Repo
  alias StepFlow.Step
  alias StepFlow.Step.Live

  def init(args) do
    {:ok, args}
  end

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def check_step_status(message) do
    GenServer.cast(__MODULE__, {:check_step_status, message})
  end

  def check_step_progression(message) do
    GenServer.cast(__MODULE__, {:check_step_progression, message})
  end

  def handle_cast({:check_step_status, %{job_id: job_id}}, state) do
    Logger.warn("#{__MODULE__}: check for job #{job_id}")

    job = StepFlow.Jobs.get_job!(job_id)

    topic = "update_workflow_" <> Integer.to_string(job.workflow_id)
    StepFlow.Notification.send(topic, %{workflow_id: job.workflow_id})

    if job.is_live do
      Live.update_job_live(job_id)
    else
      job = Repo.preload(job, :workflow)
      Step.start_next(job.workflow)
    end

    {:noreply, state}
  end

  def handle_cast({:check_step_status, message}, state) do
    Logger.error("#{__MODULE__}: unable to handle message: #{inspect(message)}")
    {:noreply, state}
  end
end
