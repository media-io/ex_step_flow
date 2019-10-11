defmodule StepFlow.WorkflowsTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias StepFlow.Router
  doctest StepFlow

  @opts Router.init([])

  test "GET /" do
    {status, _headers, body} =
      conn(:get, "/")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    assert body == "Welcome to Step Flow"
  end
end
