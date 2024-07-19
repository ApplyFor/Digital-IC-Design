`timescale 1ns/10ps
module  CONV5x5(
	input		clk,
	input		reset,
	output	reg	busy,	
	input		ready,	
			
	output reg	[11:0]	iaddr,
	input signed [12:0]	idata,
	
	output	reg 	cwr,
	output  reg	[11:0]	caddr_wr,
	output reg 	[12:0] 	cdata_wr,
	output	reg 	crd,
	output reg	[11:0] 	caddr_rd,
	input 	[12:0] 	cdata_rd,
	output reg 	csel
	);


//-----Your design-----//

//state param
localparam INIT = 0;
localparam ATCONV_25PIXELS = 1;
localparam LAYER0_WRITERELU = 2;
localparam MAXPOOL_4PIXELS = 3;
localparam LAYER1_WRITECEILING = 4;
localparam FINISH = 5;

//kernel & bias
wire signed [12:0] kernel [1:25];
assign kernel[1] = 13'h0001; assign kernel[2] = 13'h1FFF; assign kernel[3] = 13'h0000; assign kernel[4] = 13'h1FFF; assign kernel[5] = 13'h0001; 
assign kernel[6] = 13'h1FFF; assign kernel[7] = 13'h0001; assign kernel[8] = 13'h0000; assign kernel[9] = 13'h0001; assign kernel[10] = 13'h1FFF;
assign kernel[11] = 13'h1FFE; assign kernel[12] = 13'h1FFF; assign kernel[13] = 13'h0008; assign kernel[14] = 13'h1FFF; assign kernel[15] = 13'h1FFE;
assign kernel[16] = 13'h1FFF; assign kernel[17] = 13'h0001; assign kernel[18] = 13'h0000; assign kernel[19] = 13'h0001; assign kernel[20] = 13'h1FFF; 
assign kernel[21] = 13'h0001; assign kernel[22] = 13'h1FFF; assign kernel[23] = 13'h0000; assign kernel[24] = 13'h1FFF; assign kernel[25] = 13'h0001; 
wire signed [12:0] bias;
assign bias = 13'h1FF4;

//regs
reg [2:0] state, nextState;
reg [11:0] center; // Coordinate (row, column) = (center[11:6], center[5:0]) //?
reg [5:0] counter; 
reg signed [25:0] convSum; // {mul_integer(18bits), mul_fraction(8bits)}
reg padx, pady;

//constant param
localparam LENGTH = 6'd63;
localparam ZERO = 6'd0; 

//wire constants
wire [5:0] cx_add2,cx_minus2,cy_add2,cy_minus2;
assign cy_add2 = center[11:6] + 6'd2;
assign cy_minus2 = center[11:6] - 6'd2;
assign cx_add2 = center[5:0] + 6'd2;
assign cx_minus2 = center[5:0] - 6'd2;

wire [5:0] cx_add1,cx_minus1,cy_add1,cy_minus1;
assign cy_add1 = center[11:6] + 6'd1;
assign cy_minus1 = center[11:6] - 6'd1;
assign cx_add1 = center[5:0] + 6'd1;
assign cx_minus1 = center[5:0] - 6'd1;

//state ctrl
always @(posedge clk or posedge reset) begin
	if(reset) state <= INIT;
	else state <= nextState;
end

//next state logic
always @(*) begin
	case (state)
		INIT: nextState = (ready)? ATCONV_25PIXELS : INIT;
		ATCONV_25PIXELS: nextState = (counter == 5'd25)? LAYER0_WRITERELU : ATCONV_25PIXELS;
		LAYER0_WRITERELU: nextState = (center == 12'd4095)? MAXPOOL_4PIXELS : ATCONV_25PIXELS;
		MAXPOOL_4PIXELS: nextState = (counter == 5'd4)? LAYER1_WRITECEILING : MAXPOOL_4PIXELS;
		LAYER1_WRITECEILING: nextState = (caddr_wr == 12'd1023)? FINISH : MAXPOOL_4PIXELS; 
		FINISH: nextState = FINISH;
		default: nextState = INIT;
	endcase
end

//main sequential circuit
always @(posedge clk or posedge reset) begin
	if (reset) begin
		busy <= 1'd0;
		iaddr <= 12'd0;
		cwr <= 1'd0;
		caddr_wr <= 12'd0;
		cdata_wr <= 13'd0;
		crd <= 1'd1;
		caddr_rd <= 12'd0;
		csel <= 1'd0;

		center <= {6'd0 , 6'd0};
		counter <= 6'd0;
		convSum <= {{9{1'b1}}, bias, 4'd0}; // Sign extension
		padx <= 1'd0;
		pady <= 1'd0;
	end
	else begin
		case (state)
			INIT:begin
				if (ready) begin
					busy <= 1'd1;
				end
			end

			ATCONV_25PIXELS:begin
				csel <= 1'd0;
				crd <= 1'd1;
				cwr <= 1'd0;

				// use the pixel get and conv with corresponding kernel ( counter==0 means no pixel get yet )
				if(counter > 5'd0) begin
					convSum <= (padx && pady) ? convSum + idata*kernel[counter] : convSum;
				end
				counter <= counter + 5'd1;

				case (counter)
					0,1,2,3,4: pady <= ((center[11:6] == 6'd0) || (center[11:6] == 6'd1))? 0 : 1;
					5,6,7,8,9: pady <= (center[11:6] == 6'd0)? 0 : 1;
					10,11,12,13,14: pady <= 1;
					15,16,17,18,19: pady <= (center[11:6] == LENGTH)? 0 : 1;
					20,21,22,23,24: pady <= ((center[11:6] == LENGTH - 6'd1) || (center[11:6] == LENGTH))? 0 : 1;
				endcase

				case (counter)
					0,5,10,15,20: padx <= ((center[5:0] == 6'd0) || (center[5:0] == 6'd1))? 0 : 1;
					1,6,11,16,21: padx <= (center[5:0] == 6'd0)? 0 : 1;
					2,7,12,17,22: padx <= 1;
					3,8,13,18,23: padx <= (center[5:0] == LENGTH)? 0 : 1;
					4,9,14,19,24: padx <= ((center[5:0] == LENGTH - 6'd1) || (center[5:0] == LENGTH))? 0 : 1;
				endcase

				// request the next corresponding pixel for convolution
				case (counter) // -> for y axis	(row)
					0,1,2,3,4: iaddr[11:6] <= ((center[11:6] == 6'd0) || (center[11:6] == 6'd1))? ZERO : cy_minus2;			    // (0,0) , (0,1) , (0,2) , (0,3) , (0,4)
					5,6,7,8,9: iaddr[11:6] <= ((center[11:6] == 6'd0) || (center[11:6] == 6'd1))? ZERO : cy_minus1;	            // (1,0) , (1,1) , (1,2) , (1,3) , (1,4)
					10,11,12,13,14: iaddr[11:6] <= center[11:6];									                                    // (2,0) , (2,1) , (2,2) , (2,3) , (2,4)
					15,16,17,18,19: iaddr[11:6] <= ((center[11:6] == LENGTH - 6'd1) || (center[11:6] == LENGTH))? LENGTH : cy_add1;	            // (3,0) , (3,1) , (3,2) , (3,3) , (3,4)
					20,21,22,23,24: iaddr[11:6] <= ((center[11:6] == LENGTH - 6'd1) || (center[11:6] == LENGTH))? LENGTH : cy_add2;	            // (4,0) , (4,1) , (4,2) , (4,3) , (4,4)
				endcase

				case (counter) // -> for x axis	(column)									
					0,5,10,15,20: iaddr[5:0] <= ((center[5:0] == 6'd0) || (center[5:0] == 6'd1))? ZERO : cx_minus2;				// (0,0) , (1,0) , (2,0) , (3,0) , (4,0)
					1,6,11,16,21: iaddr[5:0] <= ((center[5:0] == 6'd0) || (center[5:0] == 6'd1))? ZERO : cx_minus1;				// (0,1) , (1,1) , (2,1) , (3,1) , (4,1)
					2,7,12,17,22: iaddr[5:0] <= center[5:0];									                                    // (0,2) , (1,2) , (2,2) , (3,2) , (4,2)
					3,8,13,18,23: iaddr[5:0] <= ((center[5:0] == LENGTH - 6'd1) || (center[5:0] == LENGTH))? LENGTH : cx_add1;		// (0,3) , (1,3) , (2,3) , (3,3) , (4,3)
					4,9,14,19,24: iaddr[5:0] <= ((center[5:0] == LENGTH - 6'd1) || (center[5:0] == LENGTH))? LENGTH : cx_add2;		// (0,4) , (1,4) , (2,4) , (3,4) , (4,4)
				endcase
			end

			LAYER0_WRITERELU: begin
				csel <= 1'd0;
				crd <= 1'd0;
				cwr <= 1'd1;
				caddr_wr <= center;
				cdata_wr <= (convSum[25])? 13'd0 : convSum[16:4]; // ReLU
				// init the convSum and center --> kernel move to the next center and ready for convolution
				convSum <= {{9{1'b1}}, bias, 4'd0};
				center <= center + 12'd1;
				counter <= 5'd0;
			end

			MAXPOOL_4PIXELS: begin
				csel <= 1'd0;
				crd <= 1'd1;
				cwr <= 1'd0;

				// counter==0 means this cycle would send request for 1st pixel value, else comparison starts
				if (counter==0) begin
					cdata_wr <= 13'd0;
				end
				else if (cdata_rd > cdata_wr) begin 
					cdata_wr <= cdata_rd;
				end
				counter <= counter + 5'd1;

				// request the corresponding address' pixel value 
				case(counter) // -> for y axis	(row)
					0,1: caddr_rd[11:6] <= {center[9:5], 1'd0};
					2,3: caddr_rd[11:6] <= {center[9:5], 1'd1};
				endcase

				case(counter) // -> for x axis	(column)
					0,2: caddr_rd[5:0] <= {center[4:0], 1'd0};
					1,3: caddr_rd[5:0] <= {center[4:0], 1'd1};
				endcase
			end

			LAYER1_WRITECEILING: begin
				csel <= 1'd1;
				crd <= 1'd0;
				cwr <= 1'd1;
				caddr_wr <= center;
				cdata_wr <= { cdata_wr[12:4] + {8'd0,|cdata_wr[3:0]} , 4'd0 }; // Round up
				// init for next center -> kernel move to the next center
				center <= center + 12'd1; 
				counter <= 6'd0;
			end

			FINISH: begin
				busy <= 1'd0;
			end

		endcase
	end
end

endmodule