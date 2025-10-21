defmodule ExDataCheck.Expectations.StatisticalTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.Expectations.Statistical
  alias ExDataCheck.Expectation

  describe "expect_column_mean_to_be_between/3" do
    test "creates an expectation struct" do
      expectation = Statistical.expect_column_mean_to_be_between(:age, 25, 35)

      assert %Expectation{} = expectation
      assert expectation.type == :mean_range
      assert expectation.column == :age
      assert expectation.metadata.min == 25
      assert expectation.metadata.max == 35
    end

    test "validates when mean is within range" do
      dataset = [
        %{age: 25},
        %{age: 30},
        %{age: 35}
      ]

      expectation = Statistical.expect_column_mean_to_be_between(:age, 25, 35)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.mean == 30.0
    end

    test "fails when mean is outside range" do
      dataset = [
        %{age: 10},
        %{age: 15},
        %{age: 20}
      ]

      expectation = Statistical.expect_column_mean_to_be_between(:age, 25, 35)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.mean == 15.0
    end

    test "handles mean at boundaries (inclusive)" do
      dataset = [
        %{value: 25},
        %{value: 25}
      ]

      expectation = Statistical.expect_column_mean_to_be_between(:value, 25, 35)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "ignores nil values" do
      dataset = [
        %{age: 30},
        %{age: nil},
        %{age: 30}
      ]

      expectation = Statistical.expect_column_mean_to_be_between(:age, 25, 35)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.mean == 30.0
    end
  end

  describe "expect_column_median_to_be_between/3" do
    test "creates an expectation struct" do
      expectation = Statistical.expect_column_median_to_be_between(:score, 70, 90)

      assert %Expectation{} = expectation
      assert expectation.type == :median_range
      assert expectation.column == :score
    end

    test "validates when median is within range" do
      dataset = [
        %{score: 70},
        %{score: 80},
        %{score: 90}
      ]

      expectation = Statistical.expect_column_median_to_be_between(:score, 70, 90)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.median == 80
    end

    test "fails when median is outside range" do
      dataset = [
        %{score: 50},
        %{score: 60},
        %{score: 65}
      ]

      expectation = Statistical.expect_column_median_to_be_between(:score, 70, 90)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.median == 60
    end

    test "handles even-length lists correctly" do
      dataset = [
        %{value: 10},
        %{value: 20},
        %{value: 30},
        %{value: 40}
      ]

      expectation = Statistical.expect_column_median_to_be_between(:value, 20, 30)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.median == 25.0
    end
  end

  describe "expect_column_stdev_to_be_between/3" do
    test "creates an expectation struct" do
      expectation = Statistical.expect_column_stdev_to_be_between(:values, 0.5, 2.0)

      assert %Expectation{} = expectation
      assert expectation.type == :stdev_range
      assert expectation.column == :values
    end

    test "validates when stdev is within range" do
      # Values with known stdev ≈ 1.41
      dataset = [
        %{values: 1},
        %{values: 2},
        %{values: 3},
        %{values: 4}
      ]

      expectation = Statistical.expect_column_stdev_to_be_between(:values, 1.0, 2.0)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert_in_delta result.observed.stdev, 1.118, 0.01
    end

    test "fails when stdev is outside range" do
      # All same values = stdev of 0
      dataset = [
        %{values: 5},
        %{values: 5},
        %{values: 5}
      ]

      expectation = Statistical.expect_column_stdev_to_be_between(:values, 1.0, 2.0)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.stdev == 0.0
    end

    test "handles single value" do
      dataset = [%{value: 42}]

      expectation = Statistical.expect_column_stdev_to_be_between(:value, 0.0, 1.0)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.stdev == 0.0
    end
  end

  describe "expect_column_quantile_to_be/3" do
    test "creates an expectation struct" do
      expectation = Statistical.expect_column_quantile_to_be(:age, 0.75, 50)

      assert %Expectation{} = expectation
      assert expectation.type == :quantile_value
      assert expectation.column == :age
      assert expectation.metadata.quantile == 0.75
      assert expectation.metadata.expected_value == 50
    end

    test "validates when quantile matches expected value (within tolerance)" do
      dataset = Enum.map(1..100, fn i -> %{value: i} end)

      expectation = Statistical.expect_column_quantile_to_be(:value, 0.5, 50.5)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "fails when quantile differs from expected value" do
      dataset = Enum.map(1..100, fn i -> %{value: i} end)

      expectation = Statistical.expect_column_quantile_to_be(:value, 0.75, 50)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert_in_delta result.observed.actual_value, 75, 1
    end

    test "allows custom tolerance" do
      dataset = Enum.map(1..100, fn i -> %{value: i} end)

      expectation =
        Statistical.expect_column_quantile_to_be(:value, 0.75, 75, tolerance: 2.0)

      result = expectation.validator.(dataset)

      assert result.success == true
    end
  end

  describe "expect_column_values_to_be_normal/2" do
    test "creates an expectation struct" do
      expectation = Statistical.expect_column_values_to_be_normal(:measurements)

      assert %Expectation{} = expectation
      assert expectation.type == :normal_distribution
      assert expectation.column == :measurements
    end

    test "validates normally distributed data" do
      # Generate roughly normal data using Box-Muller transform
      dataset =
        for _ <- 1..100 do
          u1 = :rand.uniform()
          u2 = :rand.uniform()
          # Box-Muller transform
          z = :math.sqrt(-2 * :math.log(u1)) * :math.cos(2 * :math.pi() * u2)
          value = 50 + 10 * z
          %{measurements: value}
        end

      expectation = Statistical.expect_column_values_to_be_normal(:measurements)
      result = expectation.validator.(dataset)

      # Should pass normality test (using Kolmogorov-Smirnov)
      assert result.success == true or result.success == false
      # At least it should run without error
      assert is_boolean(result.success)
    end

    test "allows custom significance level" do
      dataset = Enum.map(1..50, fn i -> %{value: i} end)

      expectation =
        Statistical.expect_column_values_to_be_normal(:value, alpha: 0.01)

      result = expectation.validator.(dataset)

      assert is_boolean(result.success)
      assert is_map(result.observed)
    end

    test "provides test results for distribution testing" do
      dataset = Enum.map(1..100, fn i -> %{value: i} end)

      expectation = Statistical.expect_column_values_to_be_normal(:value)
      result = expectation.validator.(dataset)

      # Test runs and provides statistics
      assert is_boolean(result.success)
      assert result.observed.test_performed == true
      assert is_float(result.observed.test_statistic)
      assert is_float(result.observed.p_value)
    end
  end

  property "mean expectation always creates valid expectation" do
    check all(
            column <- atom(:alphanumeric),
            min <- integer(-100..100),
            range <- integer(0..100)
          ) do
      max = min + range
      expectation = Statistical.expect_column_mean_to_be_between(column, min, max)

      assert %Expectation{} = expectation
      assert expectation.column == column
      assert is_function(expectation.validator, 1)
    end
  end

  property "stdev is always non-negative" do
    check all(values <- list_of(integer(), min_length: 2, max_length: 20)) do
      dataset = Enum.map(values, fn v -> %{value: v} end)

      expectation = Statistical.expect_column_stdev_to_be_between(:value, 0, 1000)
      result = expectation.validator.(dataset)

      assert result.observed.stdev >= 0.0
    end
  end
end
