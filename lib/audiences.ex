defmodule BtrzAuth.Audiences do
  # CUSTOMER: "customer",
  # BETTEREZ_APP: "betterez-app",
  # MOBILE_SCANNER: "btrz-mobile-scanner",
  # API_CLIENT: "btrz-api-client"

  @valid_audiences [
    :CUSTOMER,
    :BETTEREZ_APP,
    :MOBILE_SCANNER,
    :API_CLIENT
  ]
  def valid_audiences, do: @valid_audiences

  @valid_audiences_map %{
    "customer" => :CUSTOMER,
    "betterez-app" => :BETTEREZ_APP,
    "btrz-mobile-scanner" => :MOBILE_SCANNER,
    "btrz-api-client" => :API_CLIENT
  }
  def valid_audiences_map, do: @valid_audiences_map
end
