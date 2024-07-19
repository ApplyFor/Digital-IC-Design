// 
// Designer: P76111783
//
module AddRoundKey(
    input [127:0] s,
    input [127:0] k,
    output [127:0] s_
    );

assign s_ = s ^ k;
endmodule