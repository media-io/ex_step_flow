defmodule StepFlow.UpdatesView do
  use StepFlow, :view
  alias StepFlow.UpdatesView

  def render("index.json", %{updates: updates}) do
    %{data: render_many(updates, UpdatesView, "update.json")}
  end

  def render("show.json", %{updates: update}) do
    %{data: render_one(update, UpdatesView, "update.json")}
  end

  def render("update.json", %{updates: update}) do
    %{
      id: update.id,
      datetime: update.datetime,
      job_id: update.job_id,
      parameters: update.parameters
    }
  end
end
