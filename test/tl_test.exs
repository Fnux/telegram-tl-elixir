defmodule TLTest do
  use ExUnit.Case
  doctest TL
  doctest TL.Binary

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
    assert output == expected
    assert tail == <<>>
  end

  test "Parse : ResPQ" do
    container = 85337187
    content = <<0, 45, 204, 54, 213, 197, 55, 120, 114, 180, 51, 112, 91, 197,
    26, 130, 129, 171, 97, 96, 180, 148, 233, 74, 1, 208, 216, 141, 158, 248,
    20, 35, 8, 31, 88, 126, 216, 5, 53, 225, 107, 0, 0, 0, 21, 196, 181, 28, 1,
    0, 0, 0, 33, 107, 232, 108, 2, 43, 180, 195>>

    expected = %{name: "resPQ", nonce: 237795314672715384766303660679699074,
      pq: <<31, 88, 126, 216, 5, 53, 225, 107>>,
      server_nonce: -167922097646352380287171759857591643101,
      server_public_key_fingerprints: [-4344800451088585951]}

    {output, tail} = TL.parse(container, content)
    assert output == expected
    assert tail == <<>>
  end

  test "Parse : Boolean" do
    #BoolTrue
    output = TL.Parse.deserialize(<<0xb5, 0x75, 0x72, 0x99>>, :Bool)
             |> Map.get(:name)
    assert output == "boolTrue"
    # BoolFalse
    output = TL.Parse.deserialize(<<0x37, 0x97, 0x79, 0xbc>>, :Bool)
             |> Map.get(:name)
    assert output == "boolFalse"
  end

  test "Parse : gzip_packed" do
    gzip = <<31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 53, 210, 127, 40, 220, 113,
    28, 199, 241, 111, 238, 156, 153, 219, 49, 203, 58, 51, 212, 41, 247, 135,
    214, 252, 179, 56, 187, 153, 46, 10, 181, 240, 199, 34, 132, 251, 195,
    185, 13, 155, 204, 239, 17, 219, 252, 179, 206, 239, 22, 66, 81, 172, 112,
    148, 11, 133, 252, 12, 103, 215, 246, 199, 112, 247, 223, 178, 210, 208,
    92, 78, 10, 205, 76, 236, 253, 122, 127, 253, 247, 121, 244, 252, 124,
    190, 125, 63, 239, 239, 215, 111, 101, 242, 126, 184, 32, 8, 122, 185,
    113, 243, 231, 164, 85, 120, 90, 212, 32, 204, 85, 216, 210, 200, 91, 127,
    42, 220, 142, 116, 175, 183, 105, 189, 87, 157, 43, 161, 22, 95, 199, 237,
    71, 202, 7, 169, 110, 205, 89, 78, 235, 35, 173, 73, 74, 237, 129, 158,
    155, 34, 198, 2, 251, 54, 79, 193, 247, 6, 150, 225, 168, 151, 220, 157,
    139, 126, 238, 100, 75, 41, 59, 79, 58, 10, 219, 107, 217, 1, 74, 11, 220,
    88, 196, 30, 177, 219, 224, 237, 84, 246, 247, 139, 45, 88, 81, 206, 62,
    203, 83, 202, 200, 201, 233, 236, 192, 178, 8, 184, 77, 124, 94, 187, 172,
    30, 110, 41, 96, 247, 69, 183, 192, 135, 111, 217, 66, 72, 59, 124, 87,
    60, 175, 10, 242, 247, 184, 190, 119, 213, 169, 205, 3, 239, 94, 201, 109,
    218, 164, 186, 65, 62, 85, 176, 59, 6, 93, 240, 122, 49, 219, 16, 251, 23,
    182, 198, 177, 195, 149, 18, 79, 242, 162, 129, 157, 32, 249, 12, 239, 24,
    190, 192, 255, 204, 123, 176, 171, 154, 187, 182, 63, 232, 38, 249, 253,
    224, 48, 207, 174, 41, 18, 158, 207, 94, 131, 29, 191, 93, 112, 114, 4,
    159, 63, 55, 246, 121, 145, 229, 226, 221, 28, 149, 78, 175, 4, 205, 244,
    129, 236, 29, 59, 235, 171, 86, 78, 93, 245, 138, 109, 235, 200, 128, 151,
    170, 216, 179, 119, 204, 176, 103, 255, 42, 252, 104, 119, 29, 222, 127,
    193, 253, 36, 224, 23, 156, 159, 195, 206, 152, 185, 132, 143, 19, 51, 83,
    201, 49, 67, 193, 183, 200, 143, 39, 62, 161, 199, 245, 26, 97, 93, 33,
    239, 175, 249, 184, 10, 191, 25, 11, 133, 75, 52, 223, 188, 201, 207, 196,
    121, 118, 230, 6, 250, 92, 207, 250, 216, 26, 230, 67, 205, 33, 126, 215,
    5, 245, 115, 184, 91, 220, 219, 218, 83, 2, 207, 170, 199, 216, 227, 249,
    183, 201, 93, 137, 220, 147, 158, 212, 193, 246, 144, 26, 248, 161, 198,
    4, 187, 109, 204, 193, 243, 155, 102, 120, 247, 255, 127, 113, 5, 148,
    143, 173, 219, 248, 2, 0, 0>>

    data = :zlib.gunzip gzip
    container = :binary.part(data, 0, 4) |> TL.deserialize(:int)
    content = :binary.part(data, 4, byte_size(data) - 4)

    expected = %{name: "contactStatus", status: %{name: "userStatusOffline",
was_online: 1489598653}, user_id: 13022687}

    {map, _tail} = TL.parse(container, content)
    output = map |> Map.get(:value) |> List.first

    assert output == expected
  end

  test "Parse: auth.sentCode (basic flags)" do
    {container, content} = {-212046591,  <<0, 0, 0, 0, 47, 63, 136, 89, 2, 37,
    0, 94, 3, 0, 0, 0, 134, 89, 187, 61, 5, 0, 0, 0, 18, 51, 48, 99, 102, 101,
    56, 50, 53, 99, 98, 98, 102, 49, 99, 51, 101, 57, 50, 0, 140, 21, 163, 114>>}

    {map, tail} = TL.parse container, content
    {expected_map, expected_tail} = {%{name: "rpc_result", req_msg_id: 6451475937304248320,
      result: %{name: "auth.sentCode", next_type: %{name: "auth.codeTypeSms"},
        phone_code_hash: "30cfe825cbbf1c3e92", phone_registered: true,
        type: %{length: 5, name: "auth.sentCodeTypeApp"}}}, ""}

    assert {map, tail} == {expected_map, expected_tail}
  end

  test "Build: auth.sendCode (basic flags)" do
    # Flags OFF
    serialized = TL.build("auth.sendCode", %{phone_number: "0041767780936",
      sms_type: 0, api_id: 1234, api_hash: "hashashash", lang_code: "en"})

    expected = <<236, 240, 174, 134, 0, 0, 0, 0, 13, 48, 48, 52, 49, 55, 54,
    55, 55, 56, 48, 57, 51, 54, 0, 0, 210, 4, 0, 0, 10, 104, 97, 115, 104, 97,
    115, 104, 97, 115, 104, 0>>

    assert serialized == expected

    # Flags ON
    serialized =  TL.build("auth.sendCode", %{flags: [0],
      phone_number: "0041767780936", sms_type: 0, api_id: 1234,
      api_hash: "hashashash", lang_code: "en", current_number: "BoolFalse"})

    expected = <<236, 240, 174, 134, 1, 0, 0, 0, 13, 48, 48, 52, 49, 55, 54,
    55, 55, 56, 48, 57, 51, 54, 0, 0, 66, 111, 111, 108, 70, 97, 108, 115, 101,
    210, 4, 0, 0, 10, 104, 97, 115, 104, 97, 115, 104, 97, 115, 104, 0>>

    assert serialized == expected
  end
end
