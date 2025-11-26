defmodule ExDataCheck.Expectations.Temporal do
  @moduledoc """
  Time-series and temporal data expectations.

  Validates timestamp formats, chronological ordering, date ranges,
  and temporal patterns common in time-series ML workflows.

  ## Examples

      # Validate timestamp format
      expect_column_values_to_be_valid_timestamps(:created_at)

      # Ensure chronological ordering
      expect_column_timestamps_to_be_chronological(:event_time, strict: true)

      # Validate date range
      expect_column_timestamps_to_be_within_range(:timestamp, min_date, max_date)

      # Check regular intervals (hourly data)
      expect_column_timestamp_intervals_to_be_regular(:reading_time,
        expected_interval: {1, :hour},
        tolerance: 0.1
      )

  ## Design Principles

  - **Format Flexibility**: Supports multiple timestamp formats
  - **Type Support**: Works with DateTime, NaiveDateTime, strings, and Unix timestamps
  - **Nil Handling**: Ignores nil values by default
  - **Detailed Feedback**: Provides specific violation examples

  """

  alias ExDataCheck.{Expectation, ExpectationResult}
  alias ExDataCheck.Validator.ColumnExtractor

  @doc """
  Expects all non-nil values in a column to be valid, parseable timestamps.

  Supports multiple timestamp formats:
  - DateTime structs
  - NaiveDateTime structs
  - ISO8601 strings
  - Unix timestamps (integers)
  - Common date strings

  ## Parameters

    * `column` - Column name (atom or string)
    * `opts` - Options (optional)
      * `:allow_nil` - Allow nil values (default: true)

  ## Examples

      iex> dataset = [
      ...>   %{created_at: "2025-11-25T10:00:00Z"},
      ...>   %{created_at: "2025-11-25T11:00:00Z"}
      ...> ]
      iex> expectation = ExDataCheck.Expectations.Temporal.expect_column_values_to_be_valid_timestamps(:created_at)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_column_values_to_be_valid_timestamps(atom() | String.t(), keyword()) ::
          Expectation.t()
  def expect_column_values_to_be_valid_timestamps(column, opts \\ []) do
    allow_nil = Keyword.get(opts, :allow_nil, true)

    metadata =
      opts
      |> Map.new()
      |> Map.put(:allow_nil, allow_nil)

    validator = fn dataset ->
      values = ColumnExtractor.extract(dataset, column)
      non_nil_values = Enum.reject(values, &is_nil/1)
      nil_count = length(values) - length(non_nil_values)

      {valid, invalid} =
        Enum.split_with(non_nil_values, fn value ->
          valid_timestamp?(value)
        end)

      observed = %{
        total_values: length(non_nil_values),
        valid_count: length(valid),
        invalid_count: length(invalid),
        invalid_examples: Enum.take(invalid, 5),
        nil_count: nil_count
      }

      ExpectationResult.new(
        length(invalid) == 0,
        "expect column #{inspect(column)} values to be valid timestamps",
        observed,
        metadata
      )
    end

    Expectation.new(:valid_timestamps, column, validator, metadata)
  end

  @doc """
  Expects timestamps in a column to be in chronological order.

  Can check for strictly increasing order (no duplicates) or non-decreasing order
  (duplicates allowed).

  ## Parameters

    * `column` - Column name (atom or string)
    * `opts` - Options
      * `:strict` - Require strictly increasing (default: false, allows equal timestamps)

  ## Examples

      iex> dataset = [
      ...>   %{timestamp: ~U[2025-11-25 10:00:00Z]},
      ...>   %{timestamp: ~U[2025-11-25 11:00:00Z]},
      ...>   %{timestamp: ~U[2025-11-25 12:00:00Z]}
      ...> ]
      iex> expectation = ExDataCheck.Expectations.Temporal.expect_column_timestamps_to_be_chronological(:timestamp)
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_column_timestamps_to_be_chronological(atom() | String.t(), keyword()) ::
          Expectation.t()
  def expect_column_timestamps_to_be_chronological(column, opts \\ []) do
    strict = Keyword.get(opts, :strict, false)

    metadata =
      opts
      |> Map.new()
      |> Map.put(:strict, strict)

    validator = fn dataset ->
      values = ColumnExtractor.extract(dataset, column)
      non_nil_values = Enum.reject(values, &is_nil/1)
      nil_count = length(values) - length(non_nil_values)

      parsed =
        non_nil_values
        |> Enum.map(fn value -> {value, parse_timestamp(value)} end)

      {valid, invalid} =
        Enum.split_with(parsed, fn {_original, parsed_ts} -> parsed_ts != nil end)

      parsed_values = Enum.map(valid, fn {_original, parsed_ts} -> parsed_ts end)

      violations = find_chronology_violations(parsed_values, strict)

      observed = %{
        total_timestamps: length(parsed_values),
        violations: length(violations),
        violation_examples: Enum.take(violations, 5),
        invalid_count: length(invalid),
        invalid_examples: invalid |> Enum.map(fn {original, _} -> original end) |> Enum.take(5),
        strict_mode: strict,
        nil_count: nil_count
      }

      ExpectationResult.new(
        length(violations) == 0 and length(invalid) == 0,
        "expect column #{inspect(column)} timestamps to be chronological (strict: #{strict})",
        observed,
        metadata
      )
    end

    Expectation.new(:chronological_timestamps, column, validator, metadata)
  end

  @doc """
  Expects timestamps in a column to fall within a specified date range.

  ## Parameters

    * `column` - Column name (atom or string)
    * `min_timestamp` - Minimum timestamp (inclusive, DateTime or NaiveDateTime)
    * `max_timestamp` - Maximum timestamp (inclusive, DateTime or NaiveDateTime)

  ## Examples

      iex> min_time = ~U[2025-11-25 10:00:00Z]
      iex> max_time = ~U[2025-11-25 12:00:00Z]
      iex> dataset = [
      ...>   %{timestamp: ~U[2025-11-25 10:30:00Z]},
      ...>   %{timestamp: ~U[2025-11-25 11:00:00Z]}
      ...> ]
      iex> expectation = ExDataCheck.Expectations.Temporal.expect_column_timestamps_to_be_within_range(
      ...>   :timestamp, min_time, max_time
      ...> )
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_column_timestamps_to_be_within_range(
          atom() | String.t(),
          DateTime.t() | NaiveDateTime.t(),
          DateTime.t() | NaiveDateTime.t()
        ) :: Expectation.t()
  def expect_column_timestamps_to_be_within_range(column, min_timestamp, max_timestamp) do
    validator = fn dataset ->
      values = ColumnExtractor.extract(dataset, column)
      non_nil_values = Enum.reject(values, &is_nil/1)
      nil_count = length(values) - length(non_nil_values)

      parsed =
        non_nil_values
        |> Enum.map(fn value -> {value, parse_timestamp(value)} end)

      {valid, invalid} =
        Enum.split_with(parsed, fn {_original, parsed_ts} -> parsed_ts != nil end)

      parsed_values = Enum.map(valid, fn {_original, parsed_ts} -> parsed_ts end)

      min_parsed = normalize_timestamp(min_timestamp)
      max_parsed = normalize_timestamp(max_timestamp)

      out_of_range =
        parsed_values
        |> Enum.zip(valid)
        |> Enum.filter(fn {parsed_ts, {_original, _}} ->
          DateTime.compare(parsed_ts, min_parsed) == :lt or
            DateTime.compare(parsed_ts, max_parsed) == :gt
        end)
        |> Enum.map(fn {_parsed, {original, _}} -> original end)

      observed = %{
        total_timestamps: length(parsed_values),
        out_of_range_count: length(out_of_range),
        out_of_range_examples: Enum.take(out_of_range, 5),
        invalid_count: length(invalid),
        invalid_examples: invalid |> Enum.map(fn {original, _} -> original end) |> Enum.take(5),
        min_timestamp: min_timestamp,
        max_timestamp: max_timestamp,
        nil_count: nil_count
      }

      ExpectationResult.new(
        length(out_of_range) == 0 and length(invalid) == 0,
        "expect column #{inspect(column)} timestamps to be within range [#{min_timestamp}, #{max_timestamp}]",
        observed,
        %{min: min_timestamp, max: max_timestamp}
      )
    end

    Expectation.new(:timestamp_range, column, validator, %{
      min: min_timestamp,
      max: max_timestamp
    })
  end

  @doc """
  Expects timestamps in a column to have regular intervals between consecutive values.

  Useful for validating time-series data with expected sampling rates (hourly, daily, etc.).

  ## Parameters

    * `column` - Column name (atom or string)
    * `opts` - Options
      * `:expected_interval` - Tuple of {value, unit} where unit is :second, :minute, :hour, or :day
      * `:tolerance` - Acceptable deviation as ratio (0.1 = 10%, default: 0.05)

  ## Examples

      iex> dataset = [
      ...>   %{reading_time: ~U[2025-11-25 10:00:00Z]},
      ...>   %{reading_time: ~U[2025-11-25 11:00:00Z]},
      ...>   %{reading_time: ~U[2025-11-25 12:00:00Z]}
      ...> ]
      iex> expectation = ExDataCheck.Expectations.Temporal.expect_column_timestamp_intervals_to_be_regular(
      ...>   :reading_time,
      ...>   expected_interval: {1, :hour},
      ...>   tolerance: 0.0
      ...> )
      iex> result = expectation.validator.(dataset)
      iex> result.success
      true

  """
  @spec expect_column_timestamp_intervals_to_be_regular(atom() | String.t(), keyword()) ::
          Expectation.t()
  def expect_column_timestamp_intervals_to_be_regular(column, opts) do
    expected_interval = Keyword.fetch!(opts, :expected_interval)
    tolerance = Keyword.get(opts, :tolerance, 0.05)

    metadata =
      opts
      |> Map.new()
      |> Map.put(:expected_interval, expected_interval)
      |> Map.put(:tolerance, tolerance)

    validator = fn dataset ->
      values = ColumnExtractor.extract(dataset, column)
      non_nil_values = Enum.reject(values, &is_nil/1)
      nil_count = length(values) - length(non_nil_values)

      parsed =
        non_nil_values
        |> Enum.map(fn value -> {value, parse_timestamp(value)} end)

      {valid, invalid} =
        Enum.split_with(parsed, fn {_original, parsed_ts} -> parsed_ts != nil end)

      parsed_values = Enum.map(valid, fn {_original, parsed_ts} -> parsed_ts end)

      if length(parsed_values) < 2 do
        observed = %{
          total_timestamps: length(parsed_values),
          total_intervals: 0,
          irregular_count: 0,
          irregular_examples: [],
          invalid_count: length(invalid),
          invalid_examples: invalid |> Enum.map(fn {original, _} -> original end) |> Enum.take(5),
          nil_count: nil_count
        }

        ExpectationResult.new(
          length(invalid) == 0,
          "expect column #{inspect(column)} timestamp intervals to be regular",
          observed,
          metadata
        )
      else
        intervals = calculate_intervals(parsed_values)
        expected_seconds = interval_to_seconds(expected_interval)

        irregular =
          intervals
          |> Enum.with_index()
          |> Enum.filter(fn {interval_seconds, _idx} ->
            not within_tolerance?(interval_seconds, expected_seconds, tolerance)
          end)

        observed = %{
          total_timestamps: length(parsed_values),
          total_intervals: length(intervals),
          irregular_count: length(irregular),
          irregular_examples:
            Enum.take(irregular, 5)
            |> Enum.map(fn {seconds, idx} ->
              %{index: idx, actual_seconds: seconds, expected_seconds: expected_seconds}
            end),
          invalid_count: length(invalid),
          invalid_examples: invalid |> Enum.map(fn {original, _} -> original end) |> Enum.take(5),
          expected_interval: expected_interval,
          tolerance: tolerance,
          nil_count: nil_count
        }

        ExpectationResult.new(
          length(irregular) == 0 and length(invalid) == 0,
          "expect column #{inspect(column)} timestamp intervals to be regular (#{inspect(expected_interval)}, tolerance: #{tolerance})",
          observed,
          metadata
        )
      end
    end

    Expectation.new(:regular_timestamp_intervals, column, validator, metadata)
  end

  # Private helper functions

  defp valid_timestamp?(%DateTime{}), do: true
  defp valid_timestamp?(%NaiveDateTime{}), do: true

  defp valid_timestamp?(value) when is_integer(value) do
    # Unix timestamp - check if reasonable (after 2000, before 2100)
    value > 946_684_800 and value < 4_102_444_800
  end

  defp valid_timestamp?(value) when is_binary(value) do
    case parse_timestamp(value) do
      nil -> false
      _datetime -> true
    end
  end

  defp valid_timestamp?(_), do: false

  defp parse_timestamp(%DateTime{} = dt), do: dt
  defp parse_timestamp(%NaiveDateTime{} = ndt), do: DateTime.from_naive!(ndt, "Etc/UTC")

  defp parse_timestamp(value) when is_integer(value) do
    DateTime.from_unix(value)
    |> case do
      {:ok, dt} -> dt
      {:error, _} -> nil
    end
  end

  defp parse_timestamp(value) when is_binary(value) do
    # Try multiple formats, returning the first successful DateTime
    [
      &parse_iso_datetime/1,
      &parse_naive_iso_datetime/1,
      &parse_whitespace_datetime/1,
      &parse_us_datetime/1,
      &parse_common_formats/1
    ]
    |> Enum.find_value(& &1.(value))
  end

  defp parse_timestamp(_), do: nil

  defp parse_iso_datetime(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  defp parse_naive_iso_datetime(value) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, ndt} -> DateTime.from_naive!(ndt, "Etc/UTC")
      _ -> nil
    end
  end

  defp parse_whitespace_datetime(value) do
    normalized = String.replace(value, " ", "T")

    case NaiveDateTime.from_iso8601(normalized) do
      {:ok, ndt} -> DateTime.from_naive!(ndt, "Etc/UTC")
      _ -> nil
    end
  end

  defp parse_us_datetime(value) do
    regex =
      ~r/^(?<month>\d{1,2})\/(?<day>\d{1,2})\/(?<year>\d{4})[ T](?<hour>\d{2}):(?<minute>\d{2}):(?<second>\d{2})$/

    with %{
           "month" => month,
           "day" => day,
           "year" => year,
           "hour" => hour,
           "minute" => minute,
           "second" => second
         } <- Regex.named_captures(regex, value),
         {month_int, ""} <- Integer.parse(month),
         {day_int, ""} <- Integer.parse(day),
         {year_int, ""} <- Integer.parse(year),
         {hour_int, ""} <- Integer.parse(hour),
         {minute_int, ""} <- Integer.parse(minute),
         {second_int, ""} <- Integer.parse(second),
         {:ok, date} <- Date.new(year_int, month_int, day_int),
         {:ok, time} <- Time.new(hour_int, minute_int, second_int),
         {:ok, naive} <- NaiveDateTime.new(date, time) do
      DateTime.from_naive!(naive, "Etc/UTC")
    else
      _ -> nil
    end
  end

  defp parse_common_formats(value) do
    # ISO date only (YYYY-MM-DD)
    case Date.from_iso8601(value) do
      {:ok, date} ->
        DateTime.new!(date, ~T[00:00:00], "Etc/UTC")

      {:error, _} ->
        nil
    end
  end

  defp normalize_timestamp(%DateTime{} = dt), do: dt
  defp normalize_timestamp(%NaiveDateTime{} = ndt), do: DateTime.from_naive!(ndt, "Etc/UTC")

  defp find_chronology_violations(timestamps, strict) do
    timestamps
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.with_index()
    |> Enum.filter(fn {[prev, curr], _idx} ->
      comparison = DateTime.compare(curr, prev)

      if strict do
        comparison != :gt
      else
        comparison == :lt
      end
    end)
    |> Enum.map(fn {[prev, curr], idx} ->
      %{index: idx, previous: prev, current: curr}
    end)
  end

  defp calculate_intervals(timestamps) do
    timestamps
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [prev, curr] ->
      DateTime.diff(curr, prev, :second)
    end)
  end

  defp interval_to_seconds({value, :second}), do: value
  defp interval_to_seconds({value, :minute}), do: value * 60
  defp interval_to_seconds({value, :hour}), do: value * 3600
  defp interval_to_seconds({value, :day}), do: value * 86400

  defp within_tolerance?(actual, expected, tolerance) do
    diff = abs(actual - expected)
    allowed_diff = expected * tolerance
    diff <= allowed_diff
  end
end
