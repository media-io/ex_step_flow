defmodule StepFlow.Authentication do
  @moduledoc false

  @doc false
  defmacro __using__(opts) do
    quote do
      use unquote(Application.fetch_env!(:step_flow, :authorize))

      toto = unquote(opts)
      Logger.error("QUOTED #{inspect(toto)}")
    end
  end
end
