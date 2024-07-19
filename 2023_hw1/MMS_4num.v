module MMS_4num(result, select, number0, number1, number2, number3);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
output [7:0] result; 

/*
	Write Your Design Here ~
*/

reg	     cmp1;
reg	     cmp2;
reg	     cmp3;
reg    [7:0] output1;
reg    [7:0] output2;
reg    [7:0] result;

always @(select or number0 or number1 or number2 or number3) begin
	cmp1 = number0 < number1;
	case({select,cmp1})
		2'b00:begin
			output1 = number0;
		end
		2'b01:begin
			output1 = number1;
		end
		2'b10:begin
			output1 = number1;
		end
		2'b11:begin
			output1 = number0;
		end	endcase

	cmp2 = number2 < number3;
	case({select,cmp2})
		2'b00:begin
			output2 = number2;
		end
		2'b01:begin
			output2 = number3;
		end
		2'b10:begin
			output2 = number3;
		end
		2'b11:begin
			output2 = number2;
		end	endcase

	cmp3 = output1 < output2;
	case({select,cmp3})
		2'b00:begin
			result = output1;
		end
		2'b01:begin
			result = output2;
		end
		2'b10:begin
			result = output2;
		end
		2'b11:begin
			result = output1;
		end	endcase
end

endmodule