defmodule StepFlow.Repo do
  use Ecto.Repo,
    otp_app: :step_flow,
    show_sensitive_data_on_connection_error: true,
    adapter: Ecto.Adapters.Postgres
end
