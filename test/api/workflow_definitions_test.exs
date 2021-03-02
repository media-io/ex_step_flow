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
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
  end

  describe "workflow_definition" do
    @authorized_user %{
      rights: [
        "administrator",
        "user"
      ]
    }

    @unauthorized_user %{
      rights: []
    }

    @tag capture_log: true
    test "GET /definitions with authorized user" do
      {status, _headers, body} =
        conn(:get, "/definitions")
        |> assign(:current_user, %{rights: ["user_view"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200
      response = body |> Jason.decode!()
      assert Map.get(response, "total") == 1
    end

    @tag capture_log: true
    test "GET /definitions with unauthorized user" do
      {status, _headers, body} =
        conn(:get, "/definitions")
        |> assign(:current_user, @unauthorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200
      response = body |> Jason.decode!()
      assert Map.get(response, "total") == 0
    end

    @tag capture_log: true
    test "GET /definitions/simple_workflow with authorized user" do
      {status, _headers, body} =
        conn(:get, "/definitions/simple_workflow")
        |> assign(:current_user, %{rights: ["user_view"]})
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
    test "GET /definitions/simple_workflow with unauthorized user" do
      {status, _headers, body} =
        conn(:get, "/definitions/simple_workflow")
        |> assign(:current_user, @unauthorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 403
      response = body |> Jason.decode!()

      assert response == %{
               "errors" => [
                 %{
                   "message" => "Incorrect parameters",
                   "reason" => "Forbidden to access workflow definition with this identifier"
                 }
               ]
             }
    end

    @tag capture_log: true
    test "GET /definitions/empty_workflow.json" do
      {status, _headers, body} =
        conn(:get, "/definitions/empty_workflow.json")
        |> assign(:current_user, @authorized_user)
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
end
