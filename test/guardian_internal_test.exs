defmodule BtrzAuthTest.GuardianInternalTest do
  use ExUnit.Case

  alias BtrzAuth.GuardianInternal

  describe("subject_for_token") do
    test "for %{} given returns ok" do
      assert GuardianInternal.subject_for_token(%{}, nil) == {:ok, %{}}
    end

    test "returns error with any other" do
      assert GuardianInternal.subject_for_token(%{some: "thing"}, nil) == {:error, :invalid_resource}
    end
  end

  describe("resource_from_claims") do
    test "returns {:ok, %{}} tuple" do
      assert GuardianInternal.resource_from_claims(%{"sub" => %{}}) == {:ok, %{}}
    end

    # test "returns {:ok, %{}} tuple for any content" do
    #   assert GuardianInternal.resource_from_claims(%{"sub" => "123"}) == {:ok, %{}}
    # end
  end
end