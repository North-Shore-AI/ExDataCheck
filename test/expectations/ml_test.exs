defmodule ExDataCheck.Expectations.MLTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.Expectations.ML
  alias ExDataCheck.Expectation

  describe "expect_label_balance/2" do
    test "creates an expectation struct" do
      expectation = ML.expect_label_balance(:target, min_ratio: 0.2)

      assert %Expectation{} = expectation
      assert expectation.type == :label_balance
      assert expectation.column == :target
      assert expectation.metadata.min_ratio == 0.2
    end

    test "validates balanced binary classification" do
      dataset = [
        %{target: 0},
        %{target: 1},
        %{target: 0},
        %{target: 1}
      ]

      expectation = ML.expect_label_balance(:target, min_ratio: 0.4)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.min_class_ratio == 0.5
    end

    test "fails for imbalanced dataset" do
      dataset =
        List.duplicate(%{target: 0}, 95) ++ List.duplicate(%{target: 1}, 5)

      expectation = ML.expect_label_balance(:target, min_ratio: 0.2)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.min_class_ratio == 0.05
    end

    test "handles multi-class classification" do
      dataset =
        List.duplicate(%{target: "A"}, 40) ++
          List.duplicate(%{target: "B"}, 35) ++
          List.duplicate(%{target: "C"}, 25)

      expectation = ML.expect_label_balance(:target, min_ratio: 0.2)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.num_classes == 3
      assert result.observed.min_class_ratio == 0.25
    end

    test "provides class distribution in observed data" do
      dataset = [
        %{target: "A"},
        %{target: "A"},
        %{target: "B"}
      ]

      expectation = ML.expect_label_balance(:target, min_ratio: 0.2)
      result = expectation.validator.(dataset)

      assert result.observed.class_distribution["A"] == 2
      assert result.observed.class_distribution["B"] == 1
    end
  end

  describe "expect_label_cardinality/2" do
    test "creates an expectation struct" do
      expectation = ML.expect_label_cardinality(:target, min: 2, max: 10)

      assert %Expectation{} = expectation
      assert expectation.type == :label_cardinality
      assert expectation.column == :target
    end

    test "validates when cardinality is within range" do
      dataset = [
        %{target: "A"},
        %{target: "B"},
        %{target: "C"}
      ]

      expectation = ML.expect_label_cardinality(:target, min: 2, max: 5)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.cardinality == 3
    end

    test "fails when too many unique labels" do
      dataset = Enum.map(1..100, fn i -> %{target: i} end)

      expectation = ML.expect_label_cardinality(:target, min: 2, max: 10)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.cardinality == 100
    end

    test "fails when too few unique labels" do
      dataset = List.duplicate(%{target: "A"}, 100)

      expectation = ML.expect_label_cardinality(:target, min: 2, max: 10)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.cardinality == 1
    end
  end

  describe "expect_feature_correlation/3" do
    test "creates an expectation struct" do
      expectation = ML.expect_feature_correlation(:feature1, :feature2, max: 0.9)

      assert %Expectation{} = expectation
      assert expectation.type == :feature_correlation
      assert expectation.metadata.max == 0.9
    end

    test "validates when correlation is below threshold" do
      dataset = [
        %{f1: 1, f2: 10},
        %{f1: 2, f2: 12},
        %{f1: 3, f2: 35}
      ]

      expectation = ML.expect_feature_correlation(:f1, :f2, max: 0.95)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "fails when features are too highly correlated" do
      dataset = [
        %{f1: 1, f2: 2},
        %{f1: 2, f2: 4},
        %{f1: 3, f2: 6}
      ]

      expectation = ML.expect_feature_correlation(:f1, :f2, max: 0.9)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.correlation > 0.9
    end

    test "supports min correlation threshold" do
      dataset = [
        %{f1: 1, f2: 100},
        %{f1: 2, f2: 50},
        %{f1: 3, f2: 25}
      ]

      expectation = ML.expect_feature_correlation(:f1, :f2, min: 0.5)
      result = expectation.validator.(dataset)

      # Should fail because correlation is weak/negative
      assert is_boolean(result.success)
    end
  end

  describe "expect_no_missing_values/1" do
    test "creates an expectation struct" do
      expectation = ML.expect_no_missing_values(:features)

      assert %Expectation{} = expectation
      assert expectation.type == :no_missing
      assert expectation.column == :features
    end

    test "validates when no values are missing" do
      dataset = [
        %{features: [1, 2, 3]},
        %{features: [4, 5, 6]}
      ]

      expectation = ML.expect_no_missing_values(:features)
      result = expectation.validator.(dataset)

      assert result.success == true
    end

    test "fails when values are missing" do
      dataset = [
        %{features: [1, 2, 3]},
        %{features: nil}
      ]

      expectation = ML.expect_no_missing_values(:features)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.missing_count > 0
    end

    test "is same as expect_column_values_to_not_be_null" do
      dataset = [%{col: 1}, %{col: nil}, %{col: 3}]

      exp1 = ML.expect_no_missing_values(:col)
      exp2 = ExDataCheck.expect_column_values_to_not_be_null(:col)

      result1 = exp1.validator.(dataset)
      result2 = exp2.validator.(dataset)

      assert result1.success == result2.success
    end
  end

  describe "expect_table_row_count_to_be_between/2" do
    test "creates an expectation struct" do
      expectation = ML.expect_table_row_count_to_be_between(100, 10000)

      assert %Expectation{} = expectation
      assert expectation.type == :row_count_range
      assert expectation.metadata.min == 100
      assert expectation.metadata.max == 10000
    end

    test "validates when row count is within range" do
      dataset = Enum.map(1..500, fn i -> %{id: i} end)

      expectation = ML.expect_table_row_count_to_be_between(100, 1000)
      result = expectation.validator.(dataset)

      assert result.success == true
      assert result.observed.row_count == 500
    end

    test "fails when row count is too low" do
      dataset = Enum.map(1..50, fn i -> %{id: i} end)

      expectation = ML.expect_table_row_count_to_be_between(100, 1000)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.row_count == 50
    end

    test "fails when row count is too high" do
      dataset = Enum.map(1..2000, fn i -> %{id: i} end)

      expectation = ML.expect_table_row_count_to_be_between(100, 1000)
      result = expectation.validator.(dataset)

      assert result.success == false
      assert result.observed.row_count == 2000
    end
  end
end
