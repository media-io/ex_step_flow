defmodule StepFlow.StepHelpersTest do
  use ExUnit.Case
  use Plug.Test

  alias StepFlow.Step.Helpers

  doctest StepFlow

  describe "helpers_test" do

    test "template generation" do
      template = "{work_directory}/{date_time}/{filename}"
      workflow = %{
        id: 666,
        reference: "110e8400-e29b-11d4-a716-446655440000"
      }
      source_path = "source_folder/filename.ttml"
      dates = %{
        date: "2019_12_05",
        date_time: "2019_12_05__11_41_40"
      }

      generated = Helpers.template_process(template, workflow, dates, source_path)
      assert generated == "/test_work_dir/2019_12_05__11_41_40/filename.ttml"
    end

    test "template generation with extension" do
      template = "{work_directory}/{date_time}/{filename}{extension}"
      workflow = %{
        id: 666,
        reference: "110e8400-e29b-11d4-a716-446655440000"
      }
      source_path = "source_folder/filename.ttml"
      dates = %{
        date: "2019_12_05",
        date_time: "2019_12_05__11_41_40"
      }

      generated = Helpers.template_process(template, workflow, dates, source_path)
      assert generated == "/test_work_dir/2019_12_05__11_41_40/filename.ttml.ttml"
    end
  end
end
