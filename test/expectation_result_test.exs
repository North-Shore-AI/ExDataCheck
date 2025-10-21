defmodule ExDataCheck.ExpectationResultTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExDataCheck.ExpectationResult

  describe "ExpectationResult struct" do
    test "creates a successful result" do
      result = %ExpectationResult{
        success: true,
        expectation: "column age values between 0 and 120",
        observed: %{
          total_values: 100,
          failing_values: 0
        },
        metadata: %{min: 0, max: 120}
      }

      assert result.success == true
      assert result.expectation == "column age values between 0 and 120"
      assert result.observed.total_values == 100
      assert result.observed.failing_values == 0
    end

    test "creates a failed result with failing examples" do
      result = %ExpectationResult{
        success: false,
        expectation: "column age values between 0 and 120",
        observed: %{
          total_values: 100,
          failing_values: 2,
          failing_examples: [150, 200]
        },
        metadata: %{min: 0, max: 120}
      }

      assert result.success == false
      assert result.observed.failing_values == 2
      assert result.observed.failing_examples == [150, 200]
    end

    test "defaults metadata to empty map" do
      result = %ExpectationResult{
        success: true,
        expectation: "test expectation",
        observed: %{}
      }

      assert result.metadata == %{}
    end
  end

  describe "new/4" do
    test "creates a successful expectation result" do
      result =
        ExpectationResult.new(
          true,
          "column age values between 0 and 120",
          %{total_values: 100, failing_values: 0}
        )

      assert %ExpectationResult{} = result
      assert result.success == true
      assert result.expectation == "column age values between 0 and 120"
      assert result.observed == %{total_values: 100, failing_values: 0}
    end

    test "creates a failed expectation result" do
      result =
        ExpectationResult.new(
          false,
          "column age values between 0 and 120",
          %{total_values: 100, failing_values: 2, failing_examples: [150, 200]},
          %{min: 0, max: 120}
        )

      assert result.success == false
      assert result.observed.failing_values == 2
      assert result.metadata == %{min: 0, max: 120}
    end

    test "creates result with default metadata" do
      result =
        ExpectationResult.new(
          true,
          "test",
          %{count: 10}
        )

      assert result.metadata == %{}
    end
  end

  describe "success?/1" do
    test "returns true for successful result" do
      result = ExpectationResult.new(true, "test", %{})

      assert ExpectationResult.success?(result) == true
    end

    test "returns false for failed result" do
      result = ExpectationResult.new(false, "test", %{})

      assert ExpectationResult.success?(result) == false
    end
  end

  describe "failed?/1" do
    test "returns false for successful result" do
      result = ExpectationResult.new(true, "test", %{})

      assert ExpectationResult.failed?(result) == false
    end

    test "returns true for failed result" do
      result = ExpectationResult.new(false, "test", %{})

      assert ExpectationResult.failed?(result) == true
    end
  end

  property "success and failed are inverse" do
    check all(success <- boolean()) do
      result = ExpectationResult.new(success, "test", %{})

      assert ExpectationResult.success?(result) == !ExpectationResult.failed?(result)
    end
  end
end
