defmodule ExDataCheck.ProfilingIntegrationTest do
  use ExUnit.Case, async: true

  alias ExDataCheck.Profile

  describe "ExDataCheck.profile/1" do
    test "profiles a simple dataset" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: 30, name: "Bob"},
        %{age: 35, name: "Charlie"}
      ]

      profile = ExDataCheck.profile(dataset)

      assert %Profile{} = profile
      assert profile.row_count == 3
      assert profile.column_count == 2
      assert profile.quality_score == 1.0
    end

    test "calculates statistics for numeric columns" do
      dataset = [
        %{score: 85},
        %{score: 90},
        %{score: 95}
      ]

      profile = ExDataCheck.profile(dataset)

      score_profile = profile.columns[:score]
      assert score_profile.type == :integer
      assert score_profile.min == 85
      assert score_profile.max == 95
      assert score_profile.mean == 90.0
      assert score_profile.missing == 0
    end

    test "handles missing values" do
      dataset = [
        %{age: 25, name: "Alice"},
        %{age: nil, name: "Bob"},
        %{age: 35, name: nil}
      ]

      profile = ExDataCheck.profile(dataset)

      assert profile.missing_values[:age] == 1
      assert profile.missing_values[:name] == 1
      assert profile.quality_score < 1.0
    end

    test "infers column types correctly" do
      dataset = [
        %{
          int_col: 42,
          float_col: 3.14,
          string_col: "hello",
          bool_col: true,
          atom_col: :test
        }
      ]

      profile = ExDataCheck.profile(dataset)

      assert profile.columns[:int_col].type == :integer
      assert profile.columns[:float_col].type == :float
      assert profile.columns[:string_col].type == :string
      assert profile.columns[:bool_col].type == :boolean
      assert profile.columns[:atom_col].type == :atom
    end

    test "calculates cardinality" do
      dataset = [
        %{category: "A"},
        %{category: "B"},
        %{category: "A"},
        %{category: "C"}
      ]

      profile = ExDataCheck.profile(dataset)

      assert profile.columns[:category].cardinality == 3
    end

    test "handles empty dataset" do
      profile = ExDataCheck.profile([])

      assert profile.row_count == 0
      assert profile.column_count == 0
      assert profile.quality_score == 0.0
    end
  end

  describe "Profile export" do
    test "exports to JSON" do
      dataset = [%{age: 25}, %{age: 30}]
      profile = ExDataCheck.profile(dataset)

      json = Profile.to_json(profile)

      assert is_binary(json)
      assert json =~ "row_count"
      assert json =~ "2"
    end

    test "exports to Markdown" do
      dataset = [%{age: 25}, %{age: 30}]
      profile = ExDataCheck.profile(dataset)

      markdown = Profile.to_markdown(profile)

      assert is_binary(markdown)
      assert markdown =~ "# Data Profile"
      assert markdown =~ "Row Count"
      assert markdown =~ "2"
    end
  end
end
