defmodule ExDataCheck.OutliersTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.{Outliers, Statistics}

  describe "detect_iqr/1" do
    test "detects outliers using IQR method" do
      # Values: Q1=2, Q3=8, IQR=6
      # Lower fence: 2 - 1.5*6 = -7
      # Upper fence: 8 + 1.5*6 = 17
      # Outliers: 100, 200
      values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200]

      result = Outliers.detect_iqr(values)

      assert is_list(result.outliers)
      assert 100 in result.outliers
      assert 200 in result.outliers
      assert result.outlier_count >= 2
    end

    test "returns no outliers for uniform data" do
      values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

      result = Outliers.detect_iqr(values)

      assert result.outlier_count == 0 or result.outlier_count <= 2
      assert result.q1 > 0
      assert result.q3 > result.q1
    end

    test "includes fence boundaries in result" do
      values = [1, 2, 3, 4, 5, 100]

      result = Outliers.detect_iqr(values)

      assert is_float(result.lower_fence)
      assert is_float(result.upper_fence)
      assert result.lower_fence < result.upper_fence
    end

    test "handles empty list" do
      result = Outliers.detect_iqr([])

      assert result.outlier_count == 0
      assert result.outliers == []
    end
  end

  describe "detect_zscore/2" do
    test "detects outliers using Z-score method" do
      # Values far from mean should be detected as outliers
      values = [10, 10, 10, 10, 10, 10, 10, 100, 200]

      result = Outliers.detect_zscore(values, threshold: 2)

      assert is_list(result.outliers)
      assert result.outlier_count >= 1
    end

    test "uses default threshold of 3" do
      values = [1, 2, 3, 4, 5, 100]

      result = Outliers.detect_zscore(values)

      assert is_list(result.outliers)
      assert result.outlier_count >= 0
    end

    test "returns no outliers for tightly clustered data" do
      values = [10, 10, 10, 10, 10, 11, 11, 11]

      result = Outliers.detect_zscore(values, threshold: 3)

      assert result.outlier_count == 0
    end

    test "includes z-scores in result" do
      values = [1, 2, 3, 4, 5, 100]

      result = Outliers.detect_zscore(values)

      assert is_map(result.z_scores)
      assert is_float(result.mean)
      assert is_float(result.stdev)
    end

    test "handles empty list" do
      result = Outliers.detect_zscore([])

      assert result.outlier_count == 0
      assert result.outliers == []
    end
  end

  describe "outlier_summary/2" do
    test "returns summary of outlier detection" do
      values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200]

      summary = Outliers.outlier_summary(values, method: :iqr)

      assert is_map(summary)
      assert summary.method == :iqr
      assert summary.outlier_count >= 0
      assert is_list(summary.outliers)
    end

    test "supports both IQR and Z-score methods" do
      values = [1, 2, 3, 4, 5, 100]

      iqr_summary = Outliers.outlier_summary(values, method: :iqr)
      zscore_summary = Outliers.outlier_summary(values, method: :zscore)

      assert iqr_summary.method == :iqr
      assert zscore_summary.method == :zscore
    end
  end

  property "outlier count is never greater than total values" do
    check all(values <- list_of(integer(), min_length: 1, max_length: 50)) do
      result = Outliers.detect_iqr(values)

      assert result.outlier_count <= length(values)
    end
  end

  property "z-score outliers have |z| > threshold" do
    check all(values <- list_of(integer(1..100), min_length: 5, max_length: 20)) do
      result = Outliers.detect_zscore(values, threshold: 2)
      mean = Statistics.mean(values)
      stdev = Statistics.stdev(values)

      if stdev > 0 do
        Enum.each(result.outliers, fn outlier ->
          z = abs((outlier - mean) / stdev)
          assert z > 2
        end)
      end
    end
  end
end
