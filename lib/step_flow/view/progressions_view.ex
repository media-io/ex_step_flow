defmodule StepFlow.ProgressionsView do
  use StepFlow, :view
  alias StepFlow.ProgressionsView

  def render("index.json", %{progressions: progressions}) do
    %{data: render_many(progressions, ProgressionsView, "progression.json")}
  end

  def render("show.json", %{progressions: progression}) do
    %{data: render_one(progression, ProgressionsView, "progression.json")}
  end

  def render("progression.json", %{progressions: progression}) do
    %{
      id: progression.id,
      datetime: progression.datetime,
      docker_container_id: progression.docker_container_id,
      job_id: progression.job_id,
      progression: progression.progression
    }
  end
end
