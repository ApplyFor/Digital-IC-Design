module BITONIC_S3(  number_in1, number_in2, number_in3, number_in4,
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
wire    [7:0] tmp11;
wire    [7:0] tmp12;
wire    [7:0] tmp13;
wire    [7:0] tmp14;
wire    [7:0] tmp15;
wire    [7:0] tmp16;
wire    [7:0] tmp17;
wire    [7:0] tmp18;

BITONIC_DS    D1(number_in1, number_in5, tmp1, tmp5);
BITONIC_DS    D2(number_in2, number_in6, tmp2, tmp6);
BITONIC_DS    D3(number_in3, number_in7, tmp3, tmp7);
BITONIC_DS    D4(number_in4, number_in8, tmp4, tmp8);

BITONIC_DS    D5(tmp1, tmp3, tmp11, tmp13);
BITONIC_DS    D6(tmp5, tmp7, tmp15, tmp17);
BITONIC_DS    D7(tmp2, tmp4, tmp12, tmp14);
BITONIC_DS    D8(tmp6, tmp8, tmp16, tmp18);

BITONIC_DS    D9(tmp11, tmp12, number_out1, number_out2);
BITONIC_DS    D10(tmp13, tmp14, number_out3, number_out4);
BITONIC_DS    D11(tmp15, tmp16, number_out5, number_out6);
BITONIC_DS    D12(tmp17, tmp18, number_out7, number_out8);

endmodule
