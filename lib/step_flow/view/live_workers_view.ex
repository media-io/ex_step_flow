defmodule StepFlow.LiveWorkersView do
  use StepFlow, :view
  alias StepFlow.LiveWorkersView

  def render("index.json", %{live_workers: %{data: live_workers, total: total}}) do
    %{
      data: render_many(live_workers, LiveWorkersView, "live_worker.json"),
      total: total
    }
  end

  def render("show.json", %{live_workers: live_workers}) do
    %{data: render_one(live_workers, LiveWorkersView, "live_worker.json")}
  end

  def render("live_worker.json", %{live_workers: live_worker}) do
    %{
      id: live_worker.id,
      ips: live_worker.ips,
      ports: live_worker.ports,
      instance_id: live_worker.instance_id,
      direct_messaging_queue_name: live_worker.direct_messaging_queue_name,
      creation_date: live_worker.creation_date,
      termination_date: live_worker.termination_date,
      inserted_at: live_worker.inserted_at
    }
  end
end
