module demosaic(clk, reset, in_en, data_in, wr_r, addr_r, wdata_r, rdata_r, wr_g, addr_g, wdata_g, rdata_g, wr_b, addr_b, wdata_b, rdata_b, done);
input clk;
input reset;
input in_en;
input [7:0] data_in;
output wr_r;
output [13:0] addr_r;
output [7:0] wdata_r;
input [7:0] rdata_r;
output wr_g;
output [13:0] addr_g;
output [7:0] wdata_g;
input [7:0] rdata_g;
output wr_b;
output [13:0] addr_b;
output [7:0] wdata_b;
input [7:0] rdata_b;
output done;

//state param
localparam INIT = 0;
localparam DATA_IN = 1;
localparam BILINEAR_a = 2;
localparam BILINEAR_b = 3;
localparam BILINEAR_c = 4;
localparam BILINEAR_d = 5;
localparam WRITECHANNEL = 6;
localparam FINISH = 7;

//regs
reg wr_r;
reg [13:0] addr_r;
reg [7:0] wdata_r;
reg wr_g;
reg [13:0] addr_g;
reg [7:0] wdata_g;
reg wr_b;
reg [13:0] addr_b;
reg [7:0] wdata_b;
reg done;

reg [2:0] state, nextState;
reg [13:0] bayer [7:0];
reg [13:0] center; // Coordinate (row, column) = (center[13:7], center[6:0])
reg [3:0] counter;  //0-8:pixel delay 2 clock(1:addr 2:write)
reg [7:0] red;
reg [7:0] green;
reg [7:0] blue;

//constant param
localparam LENGTH = 7'd127;
localparam ZERO = 6'd0; 

//wire constants
wire [5:0] cx_add1,cx_minus1,cy_add1,cy_minus1;
assign cy_add1 = center[13:7] + 7'd1;
assign cy_minus1 = center[13:7] - 7'd1;
assign cx_add1 = center[6:0] + 7'd1 ;
assign cx_minus1 = center[6:0] - 7'd1;

integer i;

//state ctrl
always @(posedge clk or posedge reset) begin
	if(reset) state <= INIT;
	else state <= nextState;
end

//next state logic
always @(*) begin
	case (state)
		INIT: nextState = (in_en)? DATA_IN : INIT;
		DATA_IN: nextState = (center == 14'd16383)? BILINEAR_a : DATA_IN;
		BILINEAR_a: nextState = (counter == 4'd9)? WRITECHANNEL : BILINEAR_a;
		BILINEAR_b: nextState = (counter == 4'd9)? WRITECHANNEL : BILINEAR_b;
		BILINEAR_c: nextState = (counter == 4'd9)? WRITECHANNEL : BILINEAR_c;
		BILINEAR_d: nextState = (counter == 4'd9)? WRITECHANNEL : BILINEAR_d;
		WRITECHANNEL: begin
			if(center == 14'd16254) nextState = FINISH;
			else begin
				if(center[13:7] %2 == 0 && center[6:0] %2 == 1)  nextState = BILINEAR_c;	//R
				else if(center[13:7] %2 == 1 && center[6:0] %2 == 0)  nextState = BILINEAR_b;	//B
				else nextState = ((center[13:7]-1) %2 == 0 && center[6:0] %2 == 1)? BILINEAR_a : BILINEAR_d; //G
			end
		end
		FINISH: nextState = FINISH;
		default: nextState = INIT;
	endcase
end

//main sequential circuit
always @(posedge clk or posedge reset) begin
	if (reset) begin
		wr_r <= 1'd0;
		addr_r <= 14'd0;
		wdata_r <= 8'd0;
		wr_g <= 1'd0;
		addr_g <= 14'd0;
		wdata_g <= 8'd0;
		wr_b <= 1'd0;
		addr_b <= 14'd0;
		wdata_b <= 8'd0;
		done <= 1'd0;

		for(i = 0; i <16383; i = i + 1)  bayer[i] <= 8'd0;
		center <= {7'd0 , 7'd0};
		counter <= 4'd0;
		red <= 8'd0;
		green <= 8'd0;
		blue <= 8'd0;
	end
	else begin
		case (state)
			INIT:begin
				wr_r <= 1'd0;
				addr_r <= 14'd0;
				wdata_r <= 8'd0;
				wr_g <= 1'd0;
				addr_g <= 14'd0;
				wdata_g <= 8'd0;
				wr_b <= 1'd0;
				addr_b <= 14'd0;
				wdata_b <= 8'd0;
				done <= 1'd0;

				for(i = 0; i <16383; i = i + 1)  bayer[i] <= 8'd0;
				center <= {7'd0 , 7'd0};
				counter <= 4'd0;
				red <= 8'd0;
				green <= 8'd0;
				blue <= 8'd0;
			end

			DATA_IN:begin//read data
                bayer[center] <= data_in;
				if(center == 14'd16383) center <= 14'd129;
                else center <= center + 1;

				if(center[13:7] %2 == 0 && center[6:0] %2 == 1) begin	//R
					wr_r <= 1'd1;
					wr_g <= 1'd0;
					wr_b <= 1'd0;
					addr_r <= center;
					wdata_r <= data_in;
				end
				else if(center[13:7] %2 == 1 && center[6:0] %2 == 0) begin	//B
					wr_r <= 1'd0;
					wr_g <= 1'd0;
					wr_b <= 1'd1;
					addr_b <= center;
					wdata_b <= data_in;
				end
				else begin	//G
					wr_r <= 1'd0;
					wr_g <= 1'd1;
					wr_b <= 1'd0;
					addr_g <= center;
					wdata_g <= data_in;
				end
            end

			BILINEAR_a: begin
				wr_r <= 1'd1;
				wr_g <= 1'd0;
				wr_b <= 1'd1;

				// use the pixel get and interpolation with corresponding color ( counter==0 means no pixel get yet )
				case (counter)
					2,8: red <= red + rdata_r;
					4,6: blue <= blue + rdata_b;
				endcase
				if(counter == 4'd9) begin
					red <= red>>1;
					blue <= blue>>1;
				end
				counter <= counter + 4'd1;

				// request the next corresponding pixel for bilinear interpolation
				case (counter) // -> for y axis	(row)
					1: addr_r[13:7] <= (center[13:7] == 7'd0) ? ZERO : cy_minus1;
					3,5: addr_b[13:7] <= center[13:7];
					7: addr_r[13:7] <= (center[13:7] == LENGTH) ? LENGTH :  cy_add1;
					default: addr_g[13:7] <= center[13:7];
				endcase

				case (counter) // -> for x axis	(column)									
					1,7: addr_r[6:0] <= center[6:0];
					3: addr_b[6:0] <= (center[6:0] == 7'd0) ? ZERO : cx_minus1;
					5: addr_b[6:0] <= (center[6:0] == LENGTH) ? LENGTH : cx_add1;
					default: addr_g[6:0] <= center[6:0];
				endcase
			end

			BILINEAR_b: begin
				wr_r <= 1'd1;
				wr_g <= 1'd1;
				wr_b<= 1'd0;

				// use the pixel get and interpolation with corresponding color ( counter==0 means no pixel get yet )
				case (counter)
					1,3,7,9: red <= red + rdata_r;
					2,4,6,8: green <= green + rdata_g;
				endcase
				if(counter == 4'd9) begin
					red <= red>>2;
					green <= green>>2;
				end
				counter <= counter + 4'd1;
// reverse
				// request the next corresponding pixel for bilinear interpolation
				case (counter) // -> for y axis	(row)
					0,2: addr_r[13:7] <= (center[13:7] == 7'd0) ? ZERO : cy_minus1;
					1: addr_g[13:7] <= (center[13:7] == LENGTH) ? LENGTH : cy_minus1;
					3,5: addr_g[13:7] <= center[13:7];
					4: addr_b[13:7] <= center[13:7];
					6,8: addr_r[13:7] <= (center[13:7] == LENGTH) ? LENGTH : cy_add1;
					7: addr_g[13:7] <= (center[13:7] == LENGTH) ? LENGTH : cy_add1;
				endcase

				case (counter) // -> for x axis	(column)									
					0,6: addr_r[6:0] <= (center[6:0] == 7'd0) ? ZERO : cx_minus1;
					1,7: addr_g[6:0] <= center[6:0];
					2,8: addr_r[6:0] <= (center[6:0] == LENGTH) ? LENGTH : cx_add1;
					3: addr_g[6:0] <= (center[6:0] == 7'd0) ? ZERO : cx_minus1;
					4: addr_b[6:0] <= center[6:0];
					5: addr_g[6:0] <= (center[6:0] == LENGTH) ? LENGTH : cx_add1;
				endcase
			end

			BILINEAR_c: begin
				wr_r <= 1'd0;
				wr_g <= 1'd1;
				wr_b <= 1'd1;

				// use the pixel get and interpolation with corresponding color ( counter==0 means no pixel get yet )
				case (counter-1)
					1,3,7,9: blue <= blue + rdata_b;
					2,4,6,8: green <= green + rdata_g;
				endcase
				if(counter == 4'd9) begin
					blue <= blue>>2;
					green <= green>>2;
				end
				counter <= counter + 4'd1;
// reverse
				// request the next corresponding pixel for bilinear interpolation
				case (counter) // -> for y axis	(row)
					0,2: addr_b[13:7] <= (center[13:7] == 7'd0) ? ZERO : cy_minus1;
					1: addr_g[13:7] <= (center[13:7] == LENGTH) ? LENGTH : cy_minus1;
					3,5: addr_g[13:7] <= center[13:7];
					4: addr_r[13:7] <= center[13:7];
					6,8: addr_b[13:7] <= (center[13:7] == LENGTH) ? LENGTH : cy_add1;
					7: addr_g[13:7] <= (center[13:7] == LENGTH) ? LENGTH : cy_add1;
				endcase

				case (counter) // -> for x axis	(column)									
					0,6: addr_b[6:0] <= (center[6:0] == 7'd0) ? ZERO : cx_minus1;
					1,7: addr_g[6:0] <= center[6:0];
					2,8: addr_b[6:0] <= (center[6:0] == LENGTH) ? LENGTH : cx_add1;
					3: addr_g[6:0] <= (center[6:0] == 7'd0) ? ZERO : cx_minus1;
					4: addr_r[6:0] <= center[6:0];
					5: addr_g[6:0] <= (center[6:0] == LENGTH) ? LENGTH :  cx_add1;
				endcase
			end

			BILINEAR_d: begin
				wr_r <= 1'd1;
				wr_g <= 1'd0;
				wr_b <= 1'd1;

				// use the pixel get and interpolation with corresponding color ( counter==0 means no pixel get yet )
				case (counter)
					4,6: red <= red + rdata_r;
					2,8: blue <= blue + rdata_b;
				endcase
				if(counter == 4'd9) begin
					red <= red>>1;
					blue <= blue>>1;
				end
				counter <= counter + 4'd1;

				// request the next corresponding pixel for bilinear interpolation
				case (counter) // -> for y axis	(row)
					1: addr_b[13:7] <= (center[13:7] == 7'd0) ? ZERO : cy_minus1;
					3,5: addr_r[13:7] <= center[13:7];
					7: addr_b[13:7] <= (center[13:7] == LENGTH) ? LENGTH :  cy_add1;
					default: addr_g[13:7] <= center[13:7];
				endcase

				case (counter) // -> for x axis	(column)									
					1,7: addr_b[6:0] <= center[6:0];
					3: addr_r[6:0] <= (center[6:0] == 7'd0) ? ZERO : cx_minus1;
					5: addr_r[6:0] <= (center[6:0] == LENGTH) ? LENGTH : cx_add1;
					default: addr_g[6:0] <= center[6:0];
				endcase
			end

			WRITECHANNEL:begin
					wr_r <= (red) ? 1'd1 :0;
					wr_g <= (green) ? 1'd1 :0;
					wr_b <= (blue) ? 1'd1 :0;

					addr_r <= center;
					addr_g <= center;
					addr_b <= center;

					wdata_r <= red;
					wdata_g <= green;
					wdata_b <= blue;

					red <= 8'd0;
					green <= 8'd0;
					blue <= 8'd0;

					if(center[6:0] == 7'd126) center <= center + 3;
					else center <= center + 1;
			end

			FINISH: begin
				done <= 1'd1;
			end

		endcase
	end
end

endmodule
