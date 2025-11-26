defmodule ExDataCheck.Expectations.TemporalTest do
  use ExUnit.Case, async: true
  doctest ExDataCheck.Expectations.Temporal

  alias ExDataCheck.Expectations.Temporal

  describe "expect_column_values_to_be_valid_timestamps/2" do
    test "succeeds when all values are valid ISO8601 timestamps" do
      dataset = [
        %{created_at: "2025-11-25T10:00:00Z"},
        %{created_at: "2025-11-25T11:00:00Z"},
        %{created_at: "2025-11-25T12:00:00Z"}
      ]

      expectation = Temporal.expect_column_values_to_be_valid_timestamps(:created_at)
      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.total_values == 3
      assert result.observed.invalid_count == 0
    end

    test "succeeds when all values are DateTime structs" do
      dataset = [
        %{timestamp: ~U[2025-11-25 10:00:00Z]},
        %{timestamp: ~U[2025-11-25 11:00:00Z]},
        %{timestamp: ~U[2025-11-25 12:00:00Z]}
      ]

      expectation = Temporal.expect_column_values_to_be_valid_timestamps(:timestamp)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "succeeds when all values are NaiveDateTime structs" do
      dataset = [
        %{event_time: ~N[2025-11-25 10:00:00]},
        %{event_time: ~N[2025-11-25 11:00:00]}
      ]

      expectation = Temporal.expect_column_values_to_be_valid_timestamps(:event_time)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "fails when values are invalid timestamp strings" do
      dataset = [
        %{created_at: "2025-11-25T10:00:00Z"},
        %{created_at: "not a timestamp"},
        %{created_at: "2025-13-45T25:99:99Z"}
      ]

      expectation = Temporal.expect_column_values_to_be_valid_timestamps(:created_at)
      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.invalid_count == 2
      assert length(result.observed.invalid_examples) == 2
      assert "not a timestamp" in result.observed.invalid_examples
    end

    test "ignores nil values by default" do
      dataset = [
        %{created_at: "2025-11-25T10:00:00Z"},
        %{created_at: nil},
        %{created_at: "2025-11-25T11:00:00Z"}
      ]

      expectation = Temporal.expect_column_values_to_be_valid_timestamps(:created_at)
      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.total_values == 2
      assert result.observed.nil_count == 1
    end

    test "supports multiple common timestamp formats" do
      dataset = [
        %{time: "2025-11-25T10:00:00Z"},
        %{time: "2025-11-25 10:00:00"},
        %{time: "11/25/2025 10:00:00"},
        %{time: "2025-11-25"}
      ]

      expectation = Temporal.expect_column_values_to_be_valid_timestamps(:time)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "supports Unix timestamps (integers)" do
      dataset = [
        %{timestamp: 1_732_531_200},
        %{timestamp: 1_732_534_800},
        %{timestamp: 1_732_538_400}
      ]

      expectation = Temporal.expect_column_values_to_be_valid_timestamps(:timestamp)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "handles empty dataset" do
      dataset = []

      expectation = Temporal.expect_column_values_to_be_valid_timestamps(:created_at)
      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.total_values == 0
    end
  end

  describe "expect_column_timestamps_to_be_chronological/2" do
    test "succeeds when timestamps are in strictly increasing order" do
      dataset = [
        %{timestamp: ~U[2025-11-25 10:00:00Z]},
        %{timestamp: ~U[2025-11-25 11:00:00Z]},
        %{timestamp: ~U[2025-11-25 12:00:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamps_to_be_chronological(:timestamp, strict: true)

      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.total_timestamps == 3
      assert result.observed.violations == 0
    end

    test "fails when unparseable timestamps are present" do
      dataset = [
        %{timestamp: "2025-11-25T10:00:00Z"},
        %{timestamp: "not-a-time"},
        %{timestamp: "2025-11-25T11:00:00Z"}
      ]

      expectation = Temporal.expect_column_timestamps_to_be_chronological(:timestamp)
      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.invalid_count == 1
      assert "not-a-time" in result.observed.invalid_examples
    end

    test "succeeds when timestamps are non-decreasing (allows duplicates)" do
      dataset = [
        %{timestamp: ~U[2025-11-25 10:00:00Z]},
        %{timestamp: ~U[2025-11-25 10:00:00Z]},
        %{timestamp: ~U[2025-11-25 11:00:00Z]}
      ]

      expectation = Temporal.expect_column_timestamps_to_be_chronological(:timestamp)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "fails when timestamps are not in order with strict mode" do
      dataset = [
        %{timestamp: ~U[2025-11-25 10:00:00Z]},
        %{timestamp: ~U[2025-11-25 09:00:00Z]},
        %{timestamp: ~U[2025-11-25 11:00:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamps_to_be_chronological(:timestamp, strict: true)

      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.violations == 1
      assert length(result.observed.violation_examples) >= 1
    end

    test "fails when there are duplicate timestamps in strict mode" do
      dataset = [
        %{timestamp: ~U[2025-11-25 10:00:00Z]},
        %{timestamp: ~U[2025-11-25 10:00:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamps_to_be_chronological(:timestamp, strict: true)

      result = expectation.validator.(dataset)

      refute result.success
    end

    test "works with timestamp strings" do
      dataset = [
        %{created_at: "2025-11-25T10:00:00Z"},
        %{created_at: "2025-11-25T11:00:00Z"},
        %{created_at: "2025-11-25T12:00:00Z"}
      ]

      expectation = Temporal.expect_column_timestamps_to_be_chronological(:created_at)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "handles nil values by skipping them" do
      dataset = [
        %{timestamp: ~U[2025-11-25 10:00:00Z]},
        %{timestamp: nil},
        %{timestamp: ~U[2025-11-25 11:00:00Z]}
      ]

      expectation = Temporal.expect_column_timestamps_to_be_chronological(:timestamp)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "handles single timestamp" do
      dataset = [%{timestamp: ~U[2025-11-25 10:00:00Z]}]

      expectation = Temporal.expect_column_timestamps_to_be_chronological(:timestamp)
      result = expectation.validator.(dataset)

      assert result.success
    end

    test "handles empty dataset" do
      dataset = []

      expectation = Temporal.expect_column_timestamps_to_be_chronological(:timestamp)
      result = expectation.validator.(dataset)

      assert result.success
    end
  end

  describe "expect_column_timestamps_to_be_within_range/3" do
    test "succeeds when all timestamps are within range" do
      min_time = ~U[2025-11-25 10:00:00Z]
      max_time = ~U[2025-11-25 12:00:00Z]

      dataset = [
        %{timestamp: ~U[2025-11-25 10:30:00Z]},
        %{timestamp: ~U[2025-11-25 11:00:00Z]},
        %{timestamp: ~U[2025-11-25 11:30:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamps_to_be_within_range(:timestamp, min_time, max_time)

      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.total_timestamps == 3
      assert result.observed.out_of_range_count == 0
    end

    test "allows timestamps exactly at boundaries" do
      min_time = ~U[2025-11-25 10:00:00Z]
      max_time = ~U[2025-11-25 12:00:00Z]

      dataset = [
        %{timestamp: ~U[2025-11-25 10:00:00Z]},
        %{timestamp: ~U[2025-11-25 12:00:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamps_to_be_within_range(:timestamp, min_time, max_time)

      result = expectation.validator.(dataset)

      assert result.success
    end

    test "fails when timestamps are outside range" do
      min_time = ~U[2025-11-25 10:00:00Z]
      max_time = ~U[2025-11-25 12:00:00Z]

      dataset = [
        %{timestamp: ~U[2025-11-25 09:00:00Z]},
        %{timestamp: ~U[2025-11-25 11:00:00Z]},
        %{timestamp: ~U[2025-11-25 13:00:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamps_to_be_within_range(:timestamp, min_time, max_time)

      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.out_of_range_count == 2
      assert length(result.observed.out_of_range_examples) == 2
    end

    test "works with timestamp strings" do
      min_time = ~U[2025-11-25 10:00:00Z]
      max_time = ~U[2025-11-25 12:00:00Z]

      dataset = [
        %{created_at: "2025-11-25T10:30:00Z"},
        %{created_at: "2025-11-25T11:00:00Z"}
      ]

      expectation =
        Temporal.expect_column_timestamps_to_be_within_range(:created_at, min_time, max_time)

      result = expectation.validator.(dataset)

      assert result.success
    end

    test "works with NaiveDateTime" do
      min_time = ~N[2025-11-25 10:00:00]
      max_time = ~N[2025-11-25 12:00:00]

      dataset = [
        %{event_time: ~N[2025-11-25 10:30:00]},
        %{event_time: ~N[2025-11-25 11:00:00]}
      ]

      expectation =
        Temporal.expect_column_timestamps_to_be_within_range(:event_time, min_time, max_time)

      result = expectation.validator.(dataset)

      assert result.success
    end

    test "ignores nil values" do
      min_time = ~U[2025-11-25 10:00:00Z]
      max_time = ~U[2025-11-25 12:00:00Z]

      dataset = [
        %{timestamp: ~U[2025-11-25 11:00:00Z]},
        %{timestamp: nil}
      ]

      expectation =
        Temporal.expect_column_timestamps_to_be_within_range(:timestamp, min_time, max_time)

      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.nil_count == 1
    end
  end

  describe "expect_column_timestamp_intervals_to_be_regular/2" do
    test "succeeds when intervals are exactly regular" do
      dataset = [
        %{reading_time: ~U[2025-11-25 10:00:00Z]},
        %{reading_time: ~U[2025-11-25 11:00:00Z]},
        %{reading_time: ~U[2025-11-25 12:00:00Z]},
        %{reading_time: ~U[2025-11-25 13:00:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamp_intervals_to_be_regular(:reading_time,
          expected_interval: {1, :hour},
          tolerance: 0.0
        )

      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.total_intervals == 3
      assert result.observed.irregular_count == 0
    end

    test "succeeds when intervals are within tolerance" do
      dataset = [
        %{reading_time: ~U[2025-11-25 10:00:00Z]},
        %{reading_time: ~U[2025-11-25 11:05:00Z]},
        %{reading_time: ~U[2025-11-25 12:00:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamp_intervals_to_be_regular(:reading_time,
          expected_interval: {1, :hour},
          tolerance: 0.1
        )

      result = expectation.validator.(dataset)

      assert result.success
    end

    test "fails when intervals are irregular" do
      dataset = [
        %{reading_time: ~U[2025-11-25 10:00:00Z]},
        %{reading_time: ~U[2025-11-25 10:30:00Z]},
        %{reading_time: ~U[2025-11-25 12:00:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamp_intervals_to_be_regular(:reading_time,
          expected_interval: {1, :hour},
          tolerance: 0.1
        )

      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.irregular_count > 0
      assert length(result.observed.irregular_examples) > 0
    end

    test "supports minute intervals" do
      dataset = [
        %{timestamp: ~U[2025-11-25 10:00:00Z]},
        %{timestamp: ~U[2025-11-25 10:05:00Z]},
        %{timestamp: ~U[2025-11-25 10:10:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamp_intervals_to_be_regular(:timestamp,
          expected_interval: {5, :minute},
          tolerance: 0.0
        )

      result = expectation.validator.(dataset)

      assert result.success
    end

    test "supports day intervals" do
      dataset = [
        %{date: ~U[2025-11-25 00:00:00Z]},
        %{date: ~U[2025-11-26 00:00:00Z]},
        %{date: ~U[2025-11-27 00:00:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamp_intervals_to_be_regular(:date,
          expected_interval: {1, :day},
          tolerance: 0.0
        )

      result = expectation.validator.(dataset)

      assert result.success
    end

    test "supports second intervals" do
      dataset = [
        %{tick: ~U[2025-11-25 10:00:00Z]},
        %{tick: ~U[2025-11-25 10:00:30Z]},
        %{tick: ~U[2025-11-25 10:01:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamp_intervals_to_be_regular(:tick,
          expected_interval: {30, :second},
          tolerance: 0.0
        )

      result = expectation.validator.(dataset)

      assert result.success
    end

    test "handles single timestamp" do
      dataset = [%{timestamp: ~U[2025-11-25 10:00:00Z]}]

      expectation =
        Temporal.expect_column_timestamp_intervals_to_be_regular(:timestamp,
          expected_interval: {1, :hour}
        )

      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.total_intervals == 0
    end

    test "handles empty dataset" do
      dataset = []

      expectation =
        Temporal.expect_column_timestamp_intervals_to_be_regular(:timestamp,
          expected_interval: {1, :hour}
        )

      result = expectation.validator.(dataset)

      assert result.success
    end

    test "ignores nil values" do
      dataset = [
        %{timestamp: ~U[2025-11-25 10:00:00Z]},
        %{timestamp: nil},
        %{timestamp: ~U[2025-11-25 11:00:00Z]}
      ]

      expectation =
        Temporal.expect_column_timestamp_intervals_to_be_regular(:timestamp,
          expected_interval: {1, :hour}
        )

      result = expectation.validator.(dataset)

      assert result.success
    end
  end
end
