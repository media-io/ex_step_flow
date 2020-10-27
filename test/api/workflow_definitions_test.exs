defmodule StepFlow.Api.WorkflowDefinitionsTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Router
  doctest StepFlow

  @opts Router.init([])

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
  end

  @tag capture_log: true
  test "GET /definitions" do
    {status, _headers, body} =
      conn(:get, "/definitions")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    response = body |> Jason.decode!()
    assert Map.get(response, "total") == 2
  end

  @tag capture_log: true
  test "GET /definitions/simple_workflow" do
    {status, _headers, body} =
      conn(:get, "/definitions/simple_workflow")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    response = body |> Jason.decode!()

    assert response["data"]["identifier"] == "simple_workflow"
    assert response["data"]["version_major"] == 0
    assert response["data"]["version_minor"] == 1
    assert response["data"]["version_micro"] == 0
    assert response["data"]["tags"] == ["speech_to_text"]
  end

  @tag capture_log: true
  test "GET /definitions/empty_workflow.json" do
    {status, _headers, body} =
      conn(:get, "/definitions/empty_workflow.json")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 422
    response = body |> Jason.decode!()

    assert response == %{
             "errors" => [
               %{
                 "message" => "Incorrect parameters",
                 "reason" => "Unable to locate workflow with this identifier"
               }
             ]
           }
  end
end
