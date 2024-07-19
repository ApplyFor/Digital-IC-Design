module BITONIC_S2(  number_in1, number_in2, number_in3, number_in4,
                    number_in5, number_in6, number_in7, number_in8,
                    number_out1, number_out2, number_out3, number_out4,
                    number_out5, number_out6, number_out7, number_out8);

input  [7:0] number_in1;
input  [7:0] number_in2;
input  [7:0] number_in3;
input  [7:0] number_in4;
input  [7:0] number_in5;
input  [7:0] number_in6;
input  [7:0] number_in7;
input  [7:0] number_in8;

output  [7:0] number_out1;
output  [7:0] number_out2;
output  [7:0] number_out3;
output  [7:0] number_out4;
output  [7:0] number_out5;
output  [7:0] number_out6;
output  [7:0] number_out7;
output  [7:0] number_out8;

wire    [7:0] tmp1;
wire    [7:0] tmp2;
wire    [7:0] tmp3;
wire    [7:0] tmp4;
wire    [7:0] tmp5;
wire    [7:0] tmp6;
wire    [7:0] tmp7;
wire    [7:0] tmp8;

BITONIC_DS    D1(number_in1, number_in3, tmp1, tmp3);
BITONIC_DS    D2(number_in2, number_in4, tmp2, tmp4);
BITONIC_AS    A1(number_in6, number_in8, tmp6, tmp8);
BITONIC_AS    A2(number_in5, number_in7, tmp5, tmp7);

BITONIC_DS    D3(tmp1, tmp2, number_out1, number_out2);
BITONIC_DS    D4(tmp3, tmp4, number_out3, number_out4);
BITONIC_AS    A3(tmp5, tmp6, number_out5, number_out6);
BITONIC_AS    A4(tmp7, tmp8, number_out7, number_out8);

endmodule