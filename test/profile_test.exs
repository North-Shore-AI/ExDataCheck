defmodule ExDataCheck.ProfileTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.Profile

  describe "Profile struct" do
    test "creates a profile with all required fields" do
      profile = %Profile{
        row_count: 100,
        column_count: 5,
        columns: %{
          age: %{type: :integer, min: 25, max: 65, mean: 42.5},
          name: %{type: :string, cardinality: 100}
        },
        missing_values: %{age: 0, name: 5},
        quality_score: 0.95,
        timestamp: DateTime.utc_now()
      }

      assert profile.row_count == 100
      assert profile.column_count == 5
      assert is_map(profile.columns)
      assert is_float(profile.quality_score)
    end
  end

  describe "new/1" do
    test "creates a profile from column profiles" do
      column_profiles = %{
        age: %{type: :integer, min: 25, max: 65, mean: 42.5, missing: 0},
        name: %{type: :string, cardinality: 95, missing: 5}
      }

      profile = Profile.new(100, column_profiles)

      assert %Profile{} = profile
      assert profile.row_count == 100
      assert profile.column_count == 2
      assert profile.columns == column_profiles
      assert is_float(profile.quality_score)
      assert %DateTime{} = profile.timestamp
    end

    test "calculates quality score based on missing values" do
      # No missing values = 1.0 quality
      column_profiles = %{
        age: %{type: :integer, missing: 0},
        name: %{type: :string, missing: 0}
      }

      profile = Profile.new(100, column_profiles)
      assert profile.quality_score == 1.0

      # Some missing values reduces quality
      column_profiles_with_missing = %{
        age: %{type: :integer, missing: 10},
        name: %{type: :string, missing: 5}
      }

      profile_with_missing = Profile.new(100, column_profiles_with_missing)
      assert profile_with_missing.quality_score < 1.0
      assert profile_with_missing.quality_score > 0.0
    end

    test "extracts missing values map" do
      column_profiles = %{
        age: %{type: :integer, missing: 0},
        name: %{type: :string, missing: 5},
        email: %{type: :string, missing: 10}
      }

      profile = Profile.new(100, column_profiles)

      assert profile.missing_values == %{age: 0, name: 5, email: 10}
    end
  end

  describe "to_json/1" do
    test "exports profile to JSON string" do
      profile = %Profile{
        row_count: 10,
        column_count: 2,
        columns: %{
          age: %{type: :integer, min: 25, max: 35}
        },
        missing_values: %{},
        quality_score: 1.0,
        timestamp: ~U[2025-01-01 00:00:00Z]
      }

      json = Profile.to_json(profile)

      assert is_binary(json)
      assert json =~ "row_count"
      assert json =~ "10"
      assert json =~ "quality_score"
    end

    test "handles nested data structures" do
      profile = %Profile{
        row_count: 10,
        column_count: 1,
        columns: %{age: %{stats: [1, 2, 3]}},
        missing_values: %{},
        quality_score: 0.95,
        timestamp: ~U[2025-01-01 00:00:00Z]
      }

      json = Profile.to_json(profile)
      assert json =~ "stats"
    end
  end

  describe "to_markdown/1" do
    test "exports profile to Markdown string" do
      profile = %Profile{
        row_count: 100,
        column_count: 3,
        columns: %{
          age: %{type: :integer, min: 25, max: 65, mean: 42.5},
          name: %{type: :string, cardinality: 95},
          email: %{type: :string, cardinality: 100}
        },
        missing_values: %{age: 0, name: 5, email: 0},
        quality_score: 0.95,
        timestamp: ~U[2025-01-01 00:00:00Z]
      }

      markdown = Profile.to_markdown(profile)

      assert is_binary(markdown)
      assert markdown =~ "# Data Profile"
      assert markdown =~ "Row Count"
      assert markdown =~ "100"
      assert markdown =~ "Column Count"
      assert markdown =~ "3"
      assert markdown =~ "Quality Score"
      assert markdown =~ "0.95"
    end

    test "includes column details" do
      profile = %Profile{
        row_count: 10,
        column_count: 1,
        columns: %{
          age: %{type: :integer, min: 20, max: 30, mean: 25.0}
        },
        missing_values: %{age: 0},
        quality_score: 1.0,
        timestamp: ~U[2025-01-01 00:00:00Z]
      }

      markdown = Profile.to_markdown(profile)

      assert markdown =~ "age"
      assert markdown =~ "integer"
      assert markdown =~ "20"
      assert markdown =~ "30"
    end
  end

  describe "quality_score/1" do
    test "returns the quality score" do
      profile = %Profile{
        row_count: 100,
        column_count: 2,
        columns: %{},
        missing_values: %{},
        quality_score: 0.87,
        timestamp: DateTime.utc_now()
      }

      assert Profile.quality_score(profile) == 0.87
    end
  end

  property "new/2 always creates valid profile" do
    check all(row_count <- positive_integer()) do
      column_profiles = %{
        col1: %{type: :integer, missing: 0}
      }

      profile = Profile.new(row_count, column_profiles)

      assert %Profile{} = profile
      assert profile.row_count == row_count
      assert profile.quality_score >= 0.0
      assert profile.quality_score <= 1.0
    end
  end
end
