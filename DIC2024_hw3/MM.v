`timescale 1ns/10ps
module MM( in_data, col_end, row_end, is_legal, out_data, rst, clk , change_row,valid,busy);
input           clk;
input           rst;
input           col_end;
input           row_end;
input      [7:0]     in_data;

output reg signed [19:0]   out_data;
output is_legal;
output reg change_row,valid,busy;

//regs
reg [2:0] state, nextState;
reg signed [7:0] mat1 [0:3][0:3]; //4x4
reg signed [7:0] mat2 [0:3][0:3]; //4x4
reg signed [19:0] mat3 [0:3][0:3]; //4x4
reg [5:0] size1; // Coordinate (row, column) = (size1[5:3], size1[2:0])
reg [5:0] size2; // Coordinate (row, column) = (size2[5:3], size2[2:0])
reg [5:0] index; // Coordinate (row, column) = (index[5:3], index[2:0])
reg [2:0] x;
reg [2:0] y;
reg [2:0] z;
reg done;
reg is_legal;

//state param
localparam DATA_IN1 = 0;
localparam DATA_IN2 = 1;
localparam MULTIPLY = 2;
localparam OUT = 3;
localparam WAIT = 4;

integer i, j;

//state ctrl
always @(posedge clk or posedge rst) begin
	if(rst) state <= DATA_IN1;
	else state <= nextState;
end

//next state logic
always @(*) begin
	/*$display("mat1 (%dx%d)", size1[5:3], size1[2:0]);
	for(i = 0; i < size1[5:3]; i = i + 1) begin
		for(j = 0; j < size1[2:0]; j = j + 1) begin
			$write("%x ", mat1[i][j]);
		end
	end
	$display("");
	$display("mat2 (%dx%d)", size2[5:3], size2[2:0]);
	for(i = 0; i < size2[5:3]; i = i + 1) begin
		for(j = 0; j < size2[2:0]; j = j + 1) begin
			$write("%x ", mat2[i][j]);
		end
	end
	$display("");*/
	case (state)
		DATA_IN1: nextState = (row_end)? DATA_IN2 : DATA_IN1;
		DATA_IN2: nextState = (row_end)? MULTIPLY : DATA_IN2;
		MULTIPLY: nextState = (done)? OUT : MULTIPLY;
		OUT: nextState = ((index[5:3] == size1[5:3]-1 && index[2:0] == size2[2:0]-1) || !is_legal)? WAIT : OUT;
		default: nextState = DATA_IN1;
	endcase
end

//main sequential circuit
always @(posedge clk or posedge rst) begin
	if (rst) begin
		for(i = 0; i < 4; i = i + 1) begin
			for(j = 0; j < 4; j = j + 1) begin
				mat1[i][j] <= 8'b0;
				mat2[i][j] <= 8'b0;
				mat3[i][j] <= 20'b0;
			end
		end
		size1 <= {3'd0 , 3'd0};
		size2 <= {3'd0 , 3'd0};
		index <= {3'd0 , 3'd0};
		x <= 3'd0;
		y <= 3'd0;
		z <= 3'd0;
		done <= 1'd0;
		is_legal <= 1'd0;
		change_row <= 1'd0;
		valid <= 1'd0;
		busy <= 1'd0;
	end
	else begin
		case (state)
			DATA_IN1:begin
				mat1[index[5:3]][index[2:0]] <= in_data;
				if(col_end) begin
					index[5:3] <= index[5:3] + 1;
					index[2:0] <= 0;
				end
				else begin
					index[2:0] <= index[2:0] + 1;
				end
				if(row_end) begin
					size1[5:3] <= index[5:3] + 1; //row
					size1[2:0] <= index[2:0] + 1; //col
					index <= 0;
				end
			end

			DATA_IN2:begin
				mat2[index[5:3]][index[2:0]] <= in_data;
				if(col_end) begin
					index[5:3] <= index[5:3] + 1;
					index[2:0] <= 0;
				end
				else begin
					index[2:0] <= index[2:0] + 1;
				end
				if(row_end) begin
					size2[5:3] <= index[5:3] + 1; //row
					size2[2:0] <= index[2:0] + 1; //col
					index <= 0;
					busy <= 1;
				end
			end
			MULTIPLY: begin
				if(size1[2:0] == size2[5:3]) begin
					is_legal <= 1;
					if(!done) begin
						if(z < size2[5:3]) begin
							//$display("(%d, %d)", x, y);
							//$display("%x * %x", mat1[size1[2:0]][z], mat2[size2[2:0]][y]);
							mat3[x][y] <= mat3[x][y] + mat1[x][z] * mat2[z][y];
							z <= z + 1;
						end
						else begin
							z <= 0;
							y <= y+1;
							if(y == size2[2:0]-1) begin
								y <= 0;
								x <= x+1;
								if(x == size1[5:3]-1) begin
									x <= 0;
									done <= 1;
								end
							end
						end
					end
				end
				else begin
					is_legal <= 0;
					done <= 1;
				end
			end

			OUT: begin
				valid <= 1;
				if(index[2:0] == size2[2:0] - 1) begin
					index[5:3] <= index[5:3]+1;
					index[2:0] <= 0;
					change_row <= 1'd1;
				end
				else begin
					index[2:0] <= index[2:0] + 1;
					change_row <= 1'd0;
				end
				out_data <= mat3[index[5:3]][index[2:0]];
			end

			WAIT: begin
				for(i = 0; i < 4; i = i + 1) begin
					for(j = 0; j < 4; j = j + 1) begin
						mat1[i][j] <= 8'b0;
						mat2[i][j] <= 8'b0;
						mat3[i][j] <= 20'b0;
					end
				end
				size1 <= {3'd0 , 3'd0};
				size2 <= {3'd0 , 3'd0};
				index <= {3'd0 , 3'd0};
				x <= 3'd0;
				y <= 3'd0;
				z <= 3'd0;
				done <= 1'd0;
				is_legal <= 1'd0;
				change_row <= 1'd0;
				valid <= 1'd0;
				busy <= 1'd0;
			end
		endcase
	end
end

endmodule
