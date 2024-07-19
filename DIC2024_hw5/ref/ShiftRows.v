// 
// Designer: P76111783
//
module ShiftRows(
    input [127:0] s,
    output  [127:0] s_
    );

    assign s_[127:120] = s[127:120];
    assign s_[95:88] = s[95:88];    
    assign s_[63:56] = s[63:56];
    assign s_[31:24] = s[31:24];

    assign s_[119:112] = s[87:80];
    assign s_[87:80] = s[55:48];
    assign s_[55:48] = s[23:16];
    assign s_[23:16] = s[119:112];

    assign s_[111:104] = s[47:40];
    assign s_[79:72] = s[15:8];
    assign s_[47:40] = s[111:104];
    assign s_[15:8] = s[79:72];

    assign s_[103:96] = s[7:0];
    assign s_[71:64] = s[103:96];
    assign s_[39:32] = s[71:64];
    assign s_[7:0] = s[39:32];
endmodule