ExUnit.start(formatters: [ExUnit.CLIFormatter])
Ecto.Adapters.SQL.Sandbox.mode(StepFlow.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:fake_server)
