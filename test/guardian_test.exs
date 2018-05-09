defmodule BtrzAuth.GuardianTest do
  use ExUnit.Case

  alias BtrzAuth.Guardian

  describe "subject_for_token" do
    test "for %{} given returns ok" do
      assert Guardian.subject_for_token(%{}, nil) == {:ok, %{}}
    end

    test "returns error with any other" do
      assert Guardian.subject_for_token(%{some: "thing"}, nil) ==
               {:error, :invalid_resource}
    end
  end

  describe "resource_from_claims" do
    test "returns {:ok, %{}} tuple" do
      assert Guardian.resource_from_claims(%{"sub" => %{}}) == {:ok, %{}}
    end
  end
end
