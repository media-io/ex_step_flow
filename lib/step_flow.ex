defmodule StepFlow do
  @moduledoc """
  StepFlow provide an entire system to manage workflows.  
  It provides differents parts:
  - Connection with a database using Ecto to store Workflow status
  - a connection with a message broker to interact with workers
  - a RESTful API to create, list and interact with workflows
  """

  @doc """
  Helper to include tools in Controllers
  """
  def controller do
    quote do
      use Phoenix.Controller, namespace: StepFlow
      use BlueBird.Controller
      import Plug.Conn
      import StepFlow.Gettext
    end
  end

  @doc """
  Helper to include tools in Views
  """
  def view do
    quote do
      use Phoenix.View,
        root: "lib/step_flow/templates",
        namespace: StepFlow

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # import StepFlow.Router.Helpers
      import StepFlow.ErrorHelpers
      import StepFlow.Gettext
    end
  end

  @doc """
  Helper to include tools in Router
  """
  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
