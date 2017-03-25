defmodule TLTest do
  use ExUnit.Case
  doctest TL

  test "Build : ping" do
    ping = TL.build "ping", %{:ping_id => 666666}
    assert ping == <<236, 119, 190, 122, 42, 44, 10, 0, 0, 0, 0, 0>>
  end

  test "Parse : ping" do
    {output, _} = TL.parse 0x7abe77ec, <<42, 44, 10, 0, 0, 0, 0, 0>>
    ping_id = Map.get(output, :ping_id)
    assert ping_id == 666666
  end

  test "Parse : Vector + nested object" do
    container = 1945237724 #msg_container
    content = <<2, 0, 0, 0, 1, 64, 248, 181, 115, 238, 116, 88, 1, 0, 0, 0, 28,
    0, 0, 0, 8, 9, 194, 158, 0, 0, 0, 0, 117, 238, 116, 88, 129, 173, 246, 133,
    250, 132, 251, 62, 46, 129, 56, 209, 172, 238, 64, 9, 1, 76, 248, 181, 115,
    238, 116, 88, 2, 0, 0, 0, 20, 0, 0, 0, 197, 115, 119, 52, 0, 0, 0, 0, 117,
    238, 116, 88, 106, 143, 11, 32, 223, 123, 106, 63>>

    expected = %{messages: [%{body: %{first_msg_id: 6373981558914678784,
        name: "new_session_created", server_salt: 666795170862760238,
        unique_id: 4538367261030133121}, bytes: 28, msg_id: 6373981553377689601,
      name: "message", seqno: 1},
    %{body: %{msg_id: 6373981558914678784, name: "pong",
        ping_id: 4569600970166341482}, bytes: 20, msg_id: 6373981553377692673,
      name: "message", seqno: 2}], name: "msg_container"}

    {output, tail} = TL.parse(container, content)
    assert tail == <<>>
    assert output == expected
  end
end
