defmodule StepFlow.Jobs.StatusTest do
  use ExUnit.Case
  use Plug.Test

  alias StepFlow.Jobs.Status

  doctest StepFlow

  test "get queued status enum label" do
    assert "queued" == Status.status_enum_label(:queued)
    assert "queued" == Status.status_enum_label(0)
  end

  test "get skipped status enum label" do
    assert "skipped" == Status.status_enum_label(:skipped)
    assert "skipped" == Status.status_enum_label(1)
  end

  test "get processing status enum label" do
    assert "processing" == Status.status_enum_label(:processing)
    assert "processing" == Status.status_enum_label(2)
  end

  test "get error status enum label" do
    assert "error" == Status.status_enum_label(:error)
    assert "error" == Status.status_enum_label(3)
  end

  test "get completed status enum label" do
    assert "completed" == Status.status_enum_label(:completed)
    assert "completed" == Status.status_enum_label(4)
  end

  test "get unknown status enum label" do
    assert "unknown" == Status.status_enum_label(:other)
    assert "unknown" == Status.status_enum_label(6)
  end

end
