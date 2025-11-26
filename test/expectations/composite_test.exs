defmodule ExDataCheck.Expectations.CompositeTest do
  use ExUnit.Case, async: true

  alias ExDataCheck.Expectations.{Composite, Schema, Value}

  describe "expect_all/1" do
    test "succeeds when all expectations pass" do
      dataset = [%{age: 30, score: 0.9}]

      expectation =
        Composite.expect_all([
          Schema.expect_column_to_exist(:age),
          Value.expect_column_values_to_be_between(:age, 0, 120)
        ])

      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.passed == 2
      assert result.observed.failed == 0
    end

    test "fails when any expectation fails" do
      dataset = [%{age: 30}]

      expectation =
        Composite.expect_all([
          Schema.expect_column_to_exist(:age),
          Schema.expect_column_to_exist(:missing)
        ])

      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.failed == 1
    end
  end

  describe "expect_any/1" do
    test "succeeds when at least one expectation passes" do
      dataset = [%{age: 30}]

      expectation =
        Composite.expect_any([
          Schema.expect_column_to_exist(:missing),
          Schema.expect_column_to_exist(:age)
        ])

      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.passed == 1
      assert result.observed.failed == 1
    end

    test "fails when all expectations fail" do
      dataset = [%{name: "Alice"}]

      expectation =
        Composite.expect_any([
          Schema.expect_column_to_exist(:age),
          Schema.expect_column_to_exist(:score)
        ])

      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.passed == 0
    end
  end

  describe "expect_at_least/2" do
    test "succeeds when threshold is met" do
      dataset = [%{age: 30, score: 0.9}]

      expectation =
        Composite.expect_at_least(2, [
          Schema.expect_column_to_exist(:age),
          Schema.expect_column_to_exist(:score),
          Value.expect_column_values_to_be_between(:age, 0, 120)
        ])

      result = expectation.validator.(dataset)

      assert result.success
      assert result.observed.passed == 3
      assert result.observed.min_required == 2
    end

    test "fails when threshold is not met" do
      dataset = [%{age: 30}]

      expectation =
        Composite.expect_at_least(2, [
          Schema.expect_column_to_exist(:age),
          Schema.expect_column_to_exist(:score),
          Value.expect_column_values_to_not_be_null(:score)
        ])

      result = expectation.validator.(dataset)

      refute result.success
      assert result.observed.passed == 1
      assert result.observed.failed == 2
    end
  end
end
