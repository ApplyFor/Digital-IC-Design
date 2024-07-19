// 
// Designer: P76111783
//
module MAS_2input(
    input signed [4:0]Din1,
    input signed [4:0]Din2,
    input [1:0]Sel,
    input signed[4:0]Q,
    output [1:0]Tcmp,
    output reg signed[4:0]TDout,
    output reg signed[3:0]Dout
);

/*Write your design here*/

always @(Sel or Din1 or Din2) begin
	case(Sel)
		2'b00:begin
			TDout = Din1 + Din2;
		end
		2'b01:begin
			TDout = Din1;
		end
		2'b10:begin
			TDout = Din1;
		end
		2'b11:begin
			TDout = Din1 - Din2;
		end
	endcase
end
	
assign Tcmp = {TDout >= Q, TDout >= 0};

always @(Tcmp or TDout or Q) begin
	case(Tcmp)
		2'b00:begin
			Dout = TDout + Q;
		end
		2'b01:begin
			Dout = TDout;
		end
		2'b10:begin
			Dout = TDout;
		end
		2'b11:begin
			Dout = TDout - Q;
		end
	endcase
end
endmodule