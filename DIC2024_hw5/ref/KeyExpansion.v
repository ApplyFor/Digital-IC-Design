// 
// Designer: P76111783
//
module KeyExpansion(
    input [3:0] round,
    input [127:0] k,
    output [127:0] k_
    );

wire [31:0] W[0:3], W_;

assign W[0] = k[127:96];
assign W[1] = k[95:64];
assign W[2] = k[63:32];
assign W[3] = k[31:0];

//RotWord SubWord
Sbox k03(.s(W[3][23:16]),.s_(W_[31:24]));
Sbox k13(.s(W[3][15:8]),.s_(W_[23:16]));
Sbox k23(.s(W[3][7:0]),.s_(W_[15:8]));
Sbox k33(.s(W[3][31:24]),.s_(W_[7:0]));

function [31:0] Rcon;
    input[3:0] round;
    case(round)    
        4'd1: Rcon=32'h01000000;
        4'd2: Rcon=32'h02000000;
        4'd3: Rcon=32'h04000000;
        4'd4: Rcon=32'h08000000;
        4'd5: Rcon=32'h10000000;
        4'd6: Rcon=32'h20000000;
        4'd7: Rcon=32'h40000000;
        4'd8: Rcon=32'h80000000;
        4'd9: Rcon=32'h1b000000;
        4'd10: Rcon=32'h36000000;
        default: Rcon=32'h00000000;
    endcase
endfunction

//xor XOR Rcon
assign k_[127:96] = W[0] ^ (W_ ^ Rcon(round));
assign k_[95:64] = W[1] ^ W[0] ^ (W_ ^ Rcon(round));
assign k_[63:32] = W[2] ^ (W[1] ^ W[0] ^ (W_ ^ Rcon(round)));
assign k_[31:0]  = W[3] ^ (W[2] ^ (W[1] ^ W[0] ^ (W_ ^ Rcon(round))));
endmodule