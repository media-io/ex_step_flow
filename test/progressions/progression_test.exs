defmodule StepFlow.Progressions.ProgressionTest do
  use ExUnit.Case
  use Plug.Test

  alias StepFlow.Progressions.Progression

  doctest StepFlow

  test "get last progression" do
    progression_list = [
      %{
        datetime: ~N[2020-01-31 09:48:53],
        docker_container_id: "unknown",
        id: 456,
        inserted_at: ~N[2020-01-31 09:48:53],
        job_id: 123,
        progression: 0,
        updated_at: ~N[2020-01-31 09:48:53]
      },
      %{
        datetime: ~N[2020-01-31 10:05:36],
        docker_container_id: "unknown",
        id: 456,
        inserted_at: ~N[2020-01-31 10:05:36],
        job_id: 123,
        progression: 50,
        updated_at: ~N[2020-01-31 10:05:36]
      }
    ]

    last_progression = Progression.get_last_progression(progression_list)

    assert 50 == last_progression.progression
  end

  test "get last progression of a progression" do
    progression = %Progression{
      datetime: ~N[2020-01-31 10:05:36],
      docker_container_id: "unknown",
      job_id: 123,
      progression: 50
    }

    assert progression == Progression.get_last_progression(progression)
  end
end
