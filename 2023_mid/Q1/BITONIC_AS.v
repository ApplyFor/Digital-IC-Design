module BITONIC_AS(number_in1, number_in2, number_out1, number_out2);
input  [7:0] number_in1;
input  [7:0] number_in2;
output [7:0] number_out1;
output [7:0] number_out2;

reg [7:0] number_out1;
reg [7:0] number_out2;

always @(*) begin
	if (number_in1 <= number_in2) begin
		number_out1 = number_in1;
		number_out2 = number_in2;
	end
	else begin
		number_out1 = number_in2;
		number_out2 = number_in1;
	end
end

endmodule