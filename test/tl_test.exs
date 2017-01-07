defmodule TLTest do
  use ExUnit.Case
  doctest TL

  test "Serialize : ping" do
    ping = TL.build "ping", %{:ping_id => 666666}
    assert ping == <<236, 119, 190, 122, 42, 44, 10, 0, 0, 0, 0, 0>>
  end

  test "Deserialize : ping" do
    {output, _} = TL.parse 0x7abe77ec, <<42, 44, 10, 0, 0, 0, 0, 0>>
    ping_id = Map.get(output, :ping_id)
    assert ping_id == 666666
  end
end
