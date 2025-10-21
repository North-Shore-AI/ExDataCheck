defmodule ExDataCheck.DriftTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.Drift

  describe "create_baseline/1" do
    test "creates baseline from dataset" do
      dataset = [
        %{age: 25, status: "active"},
        %{age: 30, status: "pending"},
        %{age: 35, status: "active"}
      ]

      baseline = Drift.create_baseline(dataset)

      assert is_map(baseline)
      assert Map.has_key?(baseline, :age)
      assert Map.has_key?(baseline, :status)
    end

    test "stores distribution statistics for numeric columns" do
      dataset = Enum.map(1..100, fn i -> %{value: i} end)

      baseline = Drift.create_baseline(dataset)

      assert baseline[:value].type == :numeric
      assert is_list(baseline[:value].values)
      assert is_float(baseline[:value].mean)
      assert is_float(baseline[:value].stdev)
    end

    test "stores frequency distribution for categorical columns" do
      dataset = [
        %{category: "A"},
        %{category: "A"},
        %{category: "B"},
        %{category: "C"}
      ]

      baseline = Drift.create_baseline(dataset)

      assert baseline[:category].type == :categorical
      assert is_map(baseline[:category].frequencies)
      assert baseline[:category].frequencies["A"] == 2
    end
  end

  describe "detect/2" do
    test "detects no drift when distributions are same" do
      baseline_data = Enum.map(1..100, fn i -> %{value: i} end)
      current_data = Enum.map(1..100, fn i -> %{value: i} end)

      baseline = Drift.create_baseline(baseline_data)
      result = Drift.detect(current_data, baseline)

      assert result.drifted == false
      assert result.columns_drifted == []
    end

    test "detects drift when distributions change significantly" do
      baseline_data = Enum.map(1..100, fn i -> %{value: i} end)
      current_data = Enum.map(200..300, fn i -> %{value: i} end)

      baseline = Drift.create_baseline(baseline_data)
      result = Drift.detect(current_data, baseline)

      assert result.drifted == true
      assert :value in result.columns_drifted
      assert result.drift_scores[:value] > 0.05
    end

    test "uses KS test for numeric columns" do
      baseline_data = Enum.map(1..100, fn i -> %{value: i / 1.0} end)
      current_data = Enum.map(1..100, fn i -> %{value: i / 1.0} end)

      baseline = Drift.create_baseline(baseline_data)
      result = Drift.detect(current_data, baseline, method: :ks)

      assert result.method == :ks
      assert is_map(result.drift_scores)
    end

    test "uses Chi-square for categorical columns" do
      baseline_data =
        List.duplicate(%{cat: "A"}, 50) ++
          List.duplicate(%{cat: "B"}, 30) ++
          List.duplicate(%{cat: "C"}, 20)

      current_data =
        List.duplicate(%{cat: "A"}, 50) ++
          List.duplicate(%{cat: "B"}, 30) ++
          List.duplicate(%{cat: "C"}, 20)

      baseline = Drift.create_baseline(baseline_data)
      result = Drift.detect(current_data, baseline)

      assert result.drifted == false
    end

    test "allows custom drift threshold" do
      baseline_data = Enum.map(1..100, fn i -> %{value: i} end)
      current_data = Enum.map(1..100, fn i -> %{value: i + 5} end)

      baseline = Drift.create_baseline(baseline_data)

      # Strict threshold
      result_strict = Drift.detect(current_data, baseline, threshold: 0.01)

      # Lenient threshold
      result_lenient = Drift.detect(current_data, baseline, threshold: 0.5)

      # Same drift score, different outcomes
      assert result_strict.drift_scores == result_lenient.drift_scores
    end
  end

  describe "ks_test/2" do
    test "compares two distributions" do
      dist1 = Enum.map(1..100, fn i -> i end)
      dist2 = Enum.map(1..100, fn i -> i end)

      {statistic, p_value} = Drift.ks_test(dist1, dist2)

      assert is_float(statistic)
      assert is_float(p_value)
      assert statistic >= 0.0
      assert p_value >= 0.0
      assert p_value <= 1.0
    end

    test "detects different distributions" do
      dist1 = Enum.map(1..100, fn i -> i end)
      dist2 = Enum.map(200..300, fn i -> i end)

      {statistic, _p_value} = Drift.ks_test(dist1, dist2)

      # Large difference should have high statistic
      assert statistic > 0.5
    end
  end

  describe "psi/2" do
    test "calculates Population Stability Index" do
      baseline_dist = %{"A" => 0.5, "B" => 0.3, "C" => 0.2}
      current_dist = %{"A" => 0.5, "B" => 0.3, "C" => 0.2}

      psi_value = Drift.psi(baseline_dist, current_dist)

      assert_in_delta psi_value, 0.0, 0.001
    end

    test "detects distribution shift" do
      baseline_dist = %{"A" => 0.5, "B" => 0.3, "C" => 0.2}
      current_dist = %{"A" => 0.2, "B" => 0.3, "C" => 0.5}

      psi_value = Drift.psi(baseline_dist, current_dist)

      assert psi_value > 0.1
    end

    test "handles new categories in current distribution" do
      baseline_dist = %{"A" => 0.5, "B" => 0.5}
      current_dist = %{"A" => 0.4, "B" => 0.4, "C" => 0.2}

      psi_value = Drift.psi(baseline_dist, current_dist)

      assert psi_value > 0
    end
  end

  property "ks_test statistic is between 0 and 1" do
    check all(
            len <- integer(10..50),
            dist1 <- list_of(integer(), length: len),
            dist2 <- list_of(integer(), length: len)
          ) do
      {statistic, _p_value} = Drift.ks_test(dist1, dist2)

      assert statistic >= 0.0
      assert statistic <= 1.0
    end
  end

  property "PSI is always non-negative" do
    check all(a_ratio <- float(min: 0.2, max: 0.4)) do
      b_ratio = 0.3
      c_ratio = 1.0 - a_ratio - b_ratio

      baseline = %{"A" => a_ratio, "B" => b_ratio, "C" => c_ratio}
      current = %{"A" => a_ratio, "B" => b_ratio, "C" => c_ratio}

      psi = Drift.psi(baseline, current)

      assert psi >= 0.0
    end
  end
end
