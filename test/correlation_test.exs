defmodule ExDataCheck.CorrelationTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.Correlation

  describe "pearson/2" do
    test "calculates Pearson correlation for perfectly correlated data" do
      x = [1, 2, 3, 4, 5]
      y = [2, 4, 6, 8, 10]

      correlation = Correlation.pearson(x, y)

      assert_in_delta correlation, 1.0, 0.001
    end

    test "calculates Pearson correlation for perfectly negatively correlated data" do
      x = [1, 2, 3, 4, 5]
      y = [10, 8, 6, 4, 2]

      correlation = Correlation.pearson(x, y)

      assert_in_delta correlation, -1.0, 0.001
    end

    test "calculates Pearson correlation for uncorrelated data" do
      x = [1, 2, 3, 4, 5]
      y = [2, 2, 2, 2, 2]

      correlation = Correlation.pearson(x, y)

      # No variance in y, correlation undefined (returns nil or 0)
      assert correlation == nil or correlation == 0.0
    end

    test "handles moderate correlation" do
      x = [1, 2, 3, 4, 5]
      y = [1.5, 3.2, 4.8, 6.1, 7.9]

      correlation = Correlation.pearson(x, y)

      assert correlation > 0.9
      assert correlation < 1.0
    end

    test "requires equal length lists" do
      x = [1, 2, 3]
      y = [1, 2, 3, 4]

      assert Correlation.pearson(x, y) == nil
    end

    test "returns nil for empty lists" do
      assert Correlation.pearson([], []) == nil
    end

    test "returns nil for single element" do
      assert Correlation.pearson([1], [1]) == nil
    end
  end

  describe "spearman/2" do
    test "calculates Spearman correlation for monotonic relationship" do
      x = [1, 2, 3, 4, 5]
      # Non-linear but monotonic
      y = [1, 4, 9, 16, 25]

      correlation = Correlation.spearman(x, y)

      assert_in_delta correlation, 1.0, 0.001
    end

    test "calculates Spearman correlation for perfectly negatively correlated data" do
      x = [1, 2, 3, 4, 5]
      y = [5, 4, 3, 2, 1]

      correlation = Correlation.spearman(x, y)

      assert_in_delta correlation, -1.0, 0.001
    end

    test "handles tied ranks" do
      x = [1, 2, 2, 3, 4]
      y = [1, 2, 2, 3, 4]

      correlation = Correlation.spearman(x, y)

      assert_in_delta correlation, 1.0, 0.001
    end

    test "returns nil for mismatched lengths" do
      assert Correlation.spearman([1, 2], [1, 2, 3]) == nil
    end
  end

  describe "correlation_matrix/1" do
    test "calculates correlation matrix for dataset" do
      dataset = [
        %{a: 1, b: 2, c: 3},
        %{a: 2, b: 4, c: 6},
        %{a: 3, b: 6, c: 9}
      ]

      matrix = Correlation.correlation_matrix(dataset, [:a, :b, :c])

      # Diagonal should be 1.0
      assert_in_delta matrix[:a][:a], 1.0, 0.001
      assert_in_delta matrix[:b][:b], 1.0, 0.001
      assert_in_delta matrix[:c][:c], 1.0, 0.001

      # All variables perfectly correlated
      assert_in_delta matrix[:a][:b], 1.0, 0.001
      assert_in_delta matrix[:a][:c], 1.0, 0.001
    end

    test "handles missing values" do
      dataset = [
        %{a: 1, b: 2},
        %{a: nil, b: 3},
        %{a: 3, b: 4}
      ]

      matrix = Correlation.correlation_matrix(dataset, [:a, :b])

      assert is_map(matrix)
    end
  end

  property "Pearson correlation is between -1 and 1" do
    check all(
            len <- integer(2..20),
            values1 <- list_of(integer(), length: len),
            values2 <- list_of(integer(), length: len)
          ) do
      correlation = Correlation.pearson(values1, values2)

      if correlation do
        assert correlation >= -1.0
        assert correlation <= 1.0
      end
    end
  end

  property "Correlation is symmetric" do
    check all(
            len <- integer(2..10),
            values1 <- list_of(float(), length: len),
            values2 <- list_of(float(), length: len)
          ) do
      corr1 = Correlation.pearson(values1, values2)
      corr2 = Correlation.pearson(values2, values1)

      if corr1 && corr2 do
        assert_in_delta corr1, corr2, 0.001
      end
    end
  end
end
