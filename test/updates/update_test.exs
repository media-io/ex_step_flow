defmodule StepFlow.Updates.UpdateTest do
  use ExUnit.Case
  use Plug.Test

  alias StepFlow.Updates.Update

  doctest StepFlow

  test "get last update" do
    update_list = [
      %{
        datetime: ~N[2020-01-31 09:48:53],
        id: 456,
        inserted_at: ~N[2020-01-31 09:48:53],
        job_id: 123,
        parameters: %{test: "tata"},
        updated_at: ~N[2020-01-31 09:48:53]
      },
      %{
        datetime: ~N[2020-01-31 10:05:36],
        id: 456,
        inserted_at: ~N[2020-01-31 10:05:36],
        job_id: 123,
        parameters: %{test: "toto"},
        updated_at: ~N[2020-01-31 10:05:36]
      }
    ]

    last_update = Update.get_last_update(update_list)

    assert %{test: "toto"} == last_update.parameters
  end

  test "get last update of a update" do
    update = %Update{
      datetime: ~N[2020-01-31 10:05:36],
      job_id: 123,
      parameters: %{test: "toto"}
    }

    assert update == Update.get_last_update(update)
  end
end
