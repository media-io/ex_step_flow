defmodule StepFlow.LaunchTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Repo
  alias StepFlow.Step.Helpers
  alias StepFlow.Step.Launch
  alias StepFlow.Workflows

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
  end

  describe "launch_test" do
    @workflow_definition %{
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      steps: [
        %{
          id: 0,
          name: "my_first_step",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: [
                "my_file_1.mov",
                "my_file_2.mov"
              ]
            }
          ]
        }
      ]
    }

    @workflow_definition_with_input_filter %{
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      steps: [
        %{
          id: 0,
          name: "my_first_step",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: [
                "my_file_1.mov",
                "my_file_2.ttml",
                "my_file_3.wav",
                "my_file_4.mov"
              ]
            },
            %{
              id: "input_filter",
              type: "filter",
              default: %{ends_with: [".ttml", ".wav"]},
              value: %{ends_with: [".ttml", ".wav"]}
            }
          ]
        }
      ]
    }

    @workflow_definition_with_select_input %{
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      steps: [
        %{
          id: 0,
          name: "my_first_step",
          mode: "one_for_many",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: [
                "my_file_1.mov",
                "my_file_2.ttml",
                "my_file_3.wav",
                "my_file_4.mov"
              ]
            },
            %{
              id: "input_filter",
              type: "filter",
              default: %{ends_with: [".ttml", ".wav"]},
              value: %{ends_with: [".ttml", ".wav"]}
            },
            %{
              id: "audio_path",
              type: "select_input",
              default: %{ends_with: [".wav"]},
              value: %{ends_with: [".wav"]}
            },
            %{
              id: "subtitle_path",
              type: "select_input",
              default: %{ends_with: [".ttml"]},
              value: %{ends_with: [".ttml"]}
            }
          ]
        }
      ]
    }

    @workflow_definition_with_select_input_and_array_of_templates_parameter %{
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      parameters: [
        %{
          id: "mov_input_path",
          type: "string",
          value: "my_file_1.mov"
        },
        %{
          id: "ttml_input_path",
          type: "string",
          value: "my_file_2.ttml"
        },
        %{
          id: "wav_input_path",
          type: "string",
          value: "my_file_3.wav"
        },
        %{
          id: "param_value_1",
          type: "string",
          value: "hello"
        },
        %{
          id: "param_value_2",
          type: "string",
          value: "world"
        }
      ],
      steps: [
        %{
          id: 0,
          name: "my_first_step",
          mode: "one_for_many",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_templates",
              value: [
                "{mov_input_path}",
                "{ttml_input_path}",
                "{wav_input_path}"
              ]
            },
            %{
              id: "input_filter",
              type: "filter",
              default: %{ends_with: [".ttml", ".wav"]},
              value: %{ends_with: [".ttml", ".wav"]}
            },
            %{
              id: "audio_path",
              type: "select_input",
              default: %{ends_with: [".wav"]},
              value: %{ends_with: [".wav"]}
            },
            %{
              id: "subtitle_path",
              type: "select_input",
              default: %{ends_with: [".ttml"]},
              value: %{ends_with: [".ttml"]}
            },
            %{
              id: "parameter_with_values",
              type: "array_of_templates",
              value: [
                "{param_value_1}",
                "{param_value_2}"
              ]
            }
          ]
        }
      ]
    }

    def workflow_fixture(workflow, attrs \\ %{}) do
      {:ok, workflow} =
        attrs
        |> Enum.into(workflow)
        |> Workflows.create_workflow()

      workflow
    end

    test "generate message" do
      workflow =
        workflow_fixture(@workflow_definition)
        |> Repo.preload([:artifacts, :jobs])

      first_file = "my_file_1.mov"
      source_path = "my_file_2.mov"
      step = @workflow_definition.steps |> List.first()
      step_name = step.name
      step_id = step.id
      dates = Helpers.get_dates()

      source_paths = Launch.get_source_paths(workflow, step, dates)
      assert source_paths == ["my_file_1.mov", "my_file_2.mov"]

      current_date_time =
        Timex.now()
        |> Timex.format!("%Y_%m_%d__%H_%M_%S", :strftime)

      current_date =
        Timex.now()
        |> Timex.format!("%Y_%m_%d", :strftime)

      message =
        Launch.generate_message_one_for_one(
          source_path,
          step,
          step_name,
          step_id,
          %{date_time: current_date_time, date: current_date},
          first_file,
          workflow
        )

      assert message.parameters == [
               %{
                 id: "source_paths",
                 type: "array_of_strings",
                 value: ["my_file_1.mov", "my_file_2.mov"]
               },
               %{"id" => "source_path", "type" => "string", "value" => "my_file_2.mov"},
               %{
                 "id" => "destination_path",
                 "type" => "string",
                 "value" =>
                   "/test_work_dir/" <> Integer.to_string(workflow.id) <> "/my_file_2.mov"
               },
               %{
                 "id" => "requirements",
                 "type" => "requirements",
                 "value" => %{
                   paths: [
                     "/test_work_dir/" <> Integer.to_string(workflow.id) <> "/my_file_1.mov"
                   ]
                 }
               }
             ]

      assert StepFlow.HelpersTest.validate_message_format(message)
    end

    test "generate message with input filter" do
      workflow =
        workflow_fixture(@workflow_definition_with_input_filter)
        |> Repo.preload([:artifacts, :jobs])

      first_file = "my_file_2.ttml"
      source_path = "my_file_3.wav"
      step = @workflow_definition_with_input_filter.steps |> List.first()
      step_name = step.name
      step_id = step.id
      dates = Helpers.get_dates()

      source_paths = Launch.get_source_paths(workflow, step, dates)

      assert source_paths == ["my_file_2.ttml", "my_file_3.wav"]

      dates = Helpers.get_dates()

      message =
        Launch.generate_message_one_for_one(
          source_path,
          step,
          step_name,
          step_id,
          dates,
          first_file,
          workflow
        )

      assert message.parameters == [
               %{
                 id: "source_paths",
                 type: "array_of_strings",
                 value: [
                   "my_file_1.mov",
                   "my_file_2.ttml",
                   "my_file_3.wav",
                   "my_file_4.mov"
                 ]
               },
               %{"type" => "string", "id" => "source_path", "value" => "my_file_3.wav"},
               %{
                 "id" => "destination_path",
                 "type" => "string",
                 "value" =>
                   "/test_work_dir/" <> Integer.to_string(workflow.id) <> "/my_file_3.wav"
               },
               %{
                 "id" => "requirements",
                 "type" => "requirements",
                 "value" => %{
                   paths: [
                     "/test_work_dir/" <> Integer.to_string(workflow.id) <> "/my_file_2.ttml"
                   ]
                 }
               }
             ]

      assert StepFlow.HelpersTest.validate_message_format(message)
    end

    test "generate message with select input" do
      workflow =
        workflow_fixture(@workflow_definition_with_select_input)
        |> Repo.preload([:artifacts, :jobs])

      step = @workflow_definition_with_select_input.steps |> List.first()
      step_name = step.name
      step_id = step.id
      dates = Helpers.get_dates()

      source_paths = Launch.get_source_paths(workflow, step, dates)

      assert source_paths == ["my_file_2.ttml", "my_file_3.wav"]

      dates = Helpers.get_dates()

      message =
        Launch.generate_message_one_for_many(
          source_paths,
          step,
          step_name,
          step_id,
          dates,
          workflow
        )

      assert message.parameters == [
               %{
                 id: "source_paths",
                 type: "array_of_strings",
                 value: [
                   "my_file_1.mov",
                   "my_file_2.ttml",
                   "my_file_3.wav",
                   "my_file_4.mov"
                 ]
               },
               %{id: "audio_path", type: "string", value: "my_file_3.wav"},
               %{:id => "subtitle_path", :type => "string", :value => "my_file_2.ttml"},
               %{
                 "id" => "source_paths",
                 "type" => "array_of_strings",
                 "value" => ["my_file_2.ttml", "my_file_3.wav"]
               },
               %{
                 "id" => "requirements",
                 "type" => "requirements",
                 "value" => %{paths: ["my_file_2.ttml", "my_file_3.wav"]}
               }
             ]

      assert StepFlow.HelpersTest.validate_message_format(message)
    end

    test "generate message with select input and array of templates parameters" do
      workflow =
        workflow_fixture(@workflow_definition_with_select_input_and_array_of_templates_parameter)
        |> Repo.preload([:artifacts, :jobs])

      step =
        @workflow_definition_with_select_input_and_array_of_templates_parameter.steps
        |> List.first()

      step_name = step.name
      step_id = step.id
      dates = Helpers.get_dates()

      source_paths = Launch.get_source_paths(workflow, step, dates)

      assert source_paths == ["my_file_2.ttml", "my_file_3.wav"]

      dates = Helpers.get_dates()

      message =
        Launch.generate_message_one_for_many(
          source_paths,
          step,
          step_name,
          step_id,
          dates,
          workflow
        )

      assert message.parameters == [
               %{
                 id: "parameter_with_values",
                 type: "array_of_strings",
                 value: ["hello", "world"]
               },
               %{id: "audio_path", type: "string", value: "my_file_3.wav"},
               %{id: "subtitle_path", type: "string", value: "my_file_2.ttml"},
               %{
                 "id" => "source_paths",
                 "type" => "array_of_strings",
                 "value" => ["my_file_1.mov", "my_file_2.ttml", "my_file_3.wav"]
               },
               %{
                 "id" => "requirements",
                 "type" => "requirements",
                 "value" => %{paths: ["my_file_1.mov", "my_file_2.ttml", "my_file_3.wav"]}
               }
             ]

      assert StepFlow.HelpersTest.validate_message_format(message)
    end
  end
end
