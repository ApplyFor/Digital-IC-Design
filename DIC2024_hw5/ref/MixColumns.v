// 
// Designer: P76111783
//

//https://crypto.stackexchange.com/questions/2402/how-to-solve-mixcolumns/95775#95775
module MixColumns(
    input [127:0] in,
    output [127:0] out
    );

// m(x) = (x8 + x4 + x3 + x + 1) = 9'h11b
// .2
function [7:0] mul2;
    input [7:0] x;
    begin
            if(x[7] == 1) mul2 = ((x << 1) ^ 8'h1b); //overflow mod m(x)
            else mul2 = x << 1; 
    end
endfunction

// .3
function [7:0] mul3;
    input [7:0] x;
    begin
            mul3 = mul2(x) ^ x;
    end
endfunction

// matrix multiplication
genvar i;

generate 
for (i = 0; i < 4; i = i + 1) begin: MixColumns_
    assign out[i*32+31:i*32+24] = mul2(in[i*32+31:i*32+24]) ^ mul3(in[i*32+23:i*32+16]) ^ in[i*32+15:i*32+8] ^ in[i*32+7:i*32];    //s0c
    assign out[i*32+23:i*32+16] = in[i*32+31:i*32+24] ^ mul2(in[i*32+23:i*32+16]) ^ mul3(in[i*32+15:i*32+8]) ^ in[i*32+7:i*32];    //s1c
    assign out[i*32+15:i*32+8] = in[i*32+31:i*32+24] ^ in[i*32+23:i*32+16] ^ mul2(in[i*32+15:i*32+8]) ^ mul3(in[i*32+7:i*32]);    //s2c
    assign out[i*32+7:i*32] = mul3(in[i*32+31:i*32+24]) ^ in[i*32+23:i*32+16] ^ in[i*32+15:i*32+8] ^ mul2(in[i*32+7:i*32]);    //s3c
end
endgenerate
endmodule