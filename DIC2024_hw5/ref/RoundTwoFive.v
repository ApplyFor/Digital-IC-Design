// 
// Designer: P76111783
//
module RoundTwoFive(
    input [127:0] plain,
    input [127:0] key,
    output [127:0] cipher
    );

wire [127:0] register_subbytes,register_shiftrows,register_mc;

SubBytes SB(.in(plain), .out(register_subbytes));
ShiftRows SR(.s(register_subbytes), .s_(register_shiftrows));
MixColumns MC(.in(register_shiftrows), .out(register_mc));
AddRoundKey ARK(.s(register_mc), .k(key), .s_(cipher));
endmodule