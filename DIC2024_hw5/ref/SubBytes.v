// 
// Designer: P76111783
//
module SubBytes(
    input [127:0] in,
    output [127:0] out
    );

Sbox S00(.s(in[127:120]), .s_(out[127:120]));
Sbox S10(.s(in[119:112]), .s_(out[119:112]));
Sbox S20(.s(in[111:104]), .s_(out[111:104]));
Sbox S30(.s(in[103:96]), .s_(out[103:96]));

Sbox S01(.s(in[95:88]), .s_(out[95:88]));
Sbox S11(.s(in[87:80]), .s_(out[87:80]));
Sbox S21(.s(in[79:72]), .s_(out[79:72]));
Sbox S31(.s(in[71:64]), .s_(out[71:64]));

Sbox S02(.s(in[63:56]), .s_(out[63:56]));
Sbox S12(.s(in[55:48]), .s_(out[55:48]));
Sbox S22(.s(in[47:40]), .s_(out[47:40]));
Sbox S32(.s(in[39:32]), .s_(out[39:32]));

Sbox S03(.s(in[31:24]), .s_(out[31:24]));
Sbox S13(.s(in[23:16]), .s_(out[23:16]));
Sbox S23(.s(in[15:8]), .s_(out[15:8]));
Sbox S33(.s(in[7:0]), .s_(out[7:0]));
endmodule