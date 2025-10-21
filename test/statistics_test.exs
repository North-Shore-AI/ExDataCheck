defmodule ExDataCheck.StatisticsTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.Statistics

  describe "min/1" do
    test "returns minimum value from list" do
      assert Statistics.min([5, 2, 8, 1, 9]) == 1
      assert Statistics.min([10.5, 3.2, 7.8]) == 3.2
    end

    test "handles single element" do
      assert Statistics.min([42]) == 42
    end

    test "returns nil for empty list" do
      assert Statistics.min([]) == nil
    end
  end

  describe "max/1" do
    test "returns maximum value from list" do
      assert Statistics.max([5, 2, 8, 1, 9]) == 9
      assert Statistics.max([10.5, 3.2, 7.8]) == 10.5
    end

    test "handles single element" do
      assert Statistics.max([42]) == 42
    end

    test "returns nil for empty list" do
      assert Statistics.max([]) == nil
    end
  end

  describe "mean/1" do
    test "calculates arithmetic mean" do
      assert Statistics.mean([1, 2, 3, 4, 5]) == 3.0
      assert Statistics.mean([10, 20, 30]) == 20.0
    end

    test "handles floats" do
      result = Statistics.mean([1.5, 2.5, 3.5])
      assert_in_delta result, 2.5, 0.001
    end

    test "returns nil for empty list" do
      assert Statistics.mean([]) == nil
    end
  end

  describe "median/1" do
    test "calculates median for odd-length list" do
      assert Statistics.median([1, 2, 3, 4, 5]) == 3
      assert Statistics.median([5, 1, 3]) == 3
    end

    test "calculates median for even-length list" do
      assert Statistics.median([1, 2, 3, 4]) == 2.5
      assert Statistics.median([10, 20, 30, 40]) == 25.0
    end

    test "handles single element" do
      assert Statistics.median([42]) == 42
    end

    test "returns nil for empty list" do
      assert Statistics.median([]) == nil
    end
  end

  describe "stdev/1" do
    test "calculates standard deviation" do
      values = [2, 4, 4, 4, 5, 5, 7, 9]
      result = Statistics.stdev(values)
      assert_in_delta result, 2.0, 0.01
    end

    test "returns 0 for identical values" do
      assert Statistics.stdev([5, 5, 5, 5]) == 0.0
    end

    test "handles single element" do
      assert Statistics.stdev([42]) == 0.0
    end

    test "returns nil for empty list" do
      assert Statistics.stdev([]) == nil
    end
  end

  describe "variance/1" do
    test "calculates variance" do
      values = [2, 4, 4, 4, 5, 5, 7, 9]
      result = Statistics.variance(values)
      assert_in_delta result, 4.0, 0.01
    end

    test "returns 0 for identical values" do
      assert Statistics.variance([5, 5, 5, 5]) == 0.0
    end

    test "returns nil for empty list" do
      assert Statistics.variance([]) == nil
    end
  end

  describe "quantile/2" do
    test "calculates quantiles" do
      values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

      assert Statistics.quantile(values, 0.25) == 3.25
      assert Statistics.quantile(values, 0.5) == 5.5
      assert Statistics.quantile(values, 0.75) == 7.75
    end

    test "handles edge cases" do
      values = [1, 2, 3, 4, 5]

      assert Statistics.quantile(values, 0.0) == 1
      assert Statistics.quantile(values, 1.0) == 5
    end

    test "returns nil for empty list" do
      assert Statistics.quantile([], 0.5) == nil
    end
  end

  describe "summary/1" do
    test "returns complete statistical summary" do
      values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

      summary = Statistics.summary(values)

      assert summary.count == 10
      assert summary.min == 1
      assert summary.max == 10
      assert summary.mean == 5.5
      assert summary.median == 5.5
      assert is_float(summary.stdev)
      assert is_float(summary.variance)
    end

    test "includes quantiles" do
      values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      summary = Statistics.summary(values)

      assert is_float(summary.q25)
      assert is_float(summary.q75)
    end

    test "handles empty list" do
      summary = Statistics.summary([])

      assert summary.count == 0
      assert summary.min == nil
      assert summary.max == nil
      assert summary.mean == nil
    end
  end

  property "min is always <= max" do
    check all(values <- list_of(integer(), min_length: 1)) do
      min_val = Statistics.min(values)
      max_val = Statistics.max(values)

      assert min_val <= max_val
    end
  end

  property "mean is between min and max" do
    check all(values <- list_of(integer(), min_length: 1)) do
      min_val = Statistics.min(values)
      max_val = Statistics.max(values)
      mean_val = Statistics.mean(values)

      assert mean_val >= min_val
      assert mean_val <= max_val
    end
  end

  property "stdev is always non-negative" do
    check all(values <- list_of(integer(), min_length: 1)) do
      stdev_val = Statistics.stdev(values)

      assert stdev_val >= 0.0
    end
  end
end
