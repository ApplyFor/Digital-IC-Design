module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output valid;
output [6:0] result;

localparam ASCII_IN = 3'd0;
localparam IN_TO_POST = 3'd1;
localparam POP = 3'd2;
localparam COUNT = 3'd3;
localparam CALC = 3'd4;
localparam OUT = 3'd5;
localparam WAIT = 3'd6;

reg valid;
reg [6:0] result;
reg [2:0] state, nextState;
reg [6:0] infix[0:15];	//2.4.2 Input Token
reg [6:0] postfix[0:15]; //2.4.2 Output = 2.4.3 Input Token
reg [6:0] stack[0:15];  //2.4.2 Stack
reg [6:0] calc[0:15];  //2.4.3 Stack
reg input_flag;
reg [3:0] token_num;
reg [3:0] infix_index;
reg [3:0] postfix_index;
reg [3:0] stack_index;
reg [6:0] calc_index; 

integer i;

always @(*) begin
    case(state)
        ASCII_IN:begin
			if (ascii_in == 61) nextState = IN_TO_POST; //=
			else nextState = ASCII_IN;
		end
		IN_TO_POST:begin
			if (infix_index == token_num-1) nextState = POP;
			else nextState = IN_TO_POST;
		end
		POP:begin
			if (stack_index == 1) nextState = COUNT;
			else nextState = POP;
        end
		COUNT:begin
			nextState = CALC;
		end
        CALC:begin
			if (postfix_index == token_num-1) nextState = OUT;
			else nextState = CALC;
        end
		OUT:begin
			nextState = WAIT;
		end
        default:begin
            nextState = ASCII_IN;
        end
	endcase
end

always @(posedge clk or posedge rst) begin
	if(rst) state <= ASCII_IN;
    else state <= nextState;
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
		for(i = 0; i < 16; i = i + 1) begin
			infix[i] <= 7'b0000;
			postfix[i] <= 7'b0000;
			stack[i] <= 7'b0000;
			calc[i] <= 7'b0000;
		end
		valid <= 1'b0;
		result <= 7'd0;
		input_flag <= 1'b0;
		token_num <= 4'd0;
		infix_index <= 4'd0;
		postfix_index <= 4'd0;
		stack_index <= 4'd0;
		calc_index <= 4'd0;
    end
    else begin
        case(state)
			ASCII_IN:begin //read token
				//$display("ASCII_IN");
				if(ready) input_flag <= 1;
				if(ascii_in != 61 && (ready || input_flag)) begin
					infix[token_num] <= ascii_in;
					token_num <= token_num+1;
				end
            end
			IN_TO_POST:begin //append token to the output string
				//$display("IN_TO_POST");
				if (infix[infix_index] >= 48 && infix[infix_index] <= 57) begin //0-9
					postfix[postfix_index] <= infix[infix_index]-48;
					infix_index <= infix_index+1;
					postfix_index <= postfix_index+1;
				end
				else if (infix[infix_index] >=97 && infix[infix_index] <= 102) begin //a-f 
					postfix[postfix_index] <= infix[infix_index]-97+10;
					infix_index <= infix_index+1;
					postfix_index <= postfix_index+1;
				end
				else if (infix[infix_index] == 43 || infix[infix_index] == 45) begin //+-
					if((stack[stack_index-1] == 43 || stack[stack_index-1] == 45 || stack[stack_index-1] == 42) && stack_index) begin
						postfix[postfix_index] <= stack[stack_index-1];
						postfix_index <= postfix_index+1;
						stack_index <= stack_index-1;
					end
					else begin
						stack[stack_index] <= infix[infix_index];
						infix_index <= infix_index+1;
						stack_index <= stack_index+1;
					end
				end
				else if (infix[infix_index] == 42) begin //*
					if(stack[stack_index-1] == 42 && stack_index) begin
						postfix[postfix_index] <= stack[stack_index-1];
						postfix_index <= postfix_index+1;
						stack_index <= stack_index-1;
					end
					else begin
						stack[stack_index] <= infix[infix_index];
						infix_index <= infix_index+1;
						stack_index <= stack_index+1;
					end
				end
				else if (infix[infix_index] == 40) begin //(
					stack[stack_index] <= infix[infix_index];
					infix_index <= infix_index+1;
					stack_index <= stack_index+1;
				end
				else if (infix[infix_index] == 41) begin //)
					if(stack[stack_index-1] != 40 && stack[stack_index-1] != 41) begin
						postfix[postfix_index] <= stack[stack_index-1];
						postfix_index <= postfix_index+1;
					end
					stack_index <= stack_index-1;
					if(stack[stack_index-1] == 40) begin
						infix_index <= infix_index+1;
					end
				end
            end
			POP:begin //pop out all the tokens in the stack
				//$display("POP");
				if(stack[stack_index-1] != 40) begin //(
					postfix[postfix_index] <= stack[stack_index-1];
					postfix_index <= postfix_index+1;
				end
				stack_index <= stack_index-1;
            end
			COUNT:begin
				token_num <=postfix_index;
				postfix_index <= 0;
			end
            CALC:begin //calculate the postfix expression
				//$display("CALC");
				if (postfix[postfix_index] == 43) begin //+
					calc[calc_index-2] <=  calc[calc_index-2]+calc[calc_index-1];
					calc_index <= calc_index-1;
				end
				else if (postfix[postfix_index] == 45) begin //-
					calc[calc_index-2] <=  calc[calc_index-2]-calc[calc_index-1];
					calc_index <= calc_index-1;
				end
				else if (postfix[postfix_index] == 42) begin //*
					calc[calc_index-2] <=  calc[calc_index-2]*calc[calc_index-1];
					calc_index <= calc_index-1;
				end
				else begin
					calc[calc_index] <= postfix[postfix_index];
					calc_index <= calc_index+1;
				end
				postfix_index <= postfix_index+1;
            end
            OUT:begin//output result
				//$display("OUT");
                valid <= 1;
				result <= calc[calc_index-1];
            end
            WAIT:begin//reset register
				//$display("WAIT");
				for(i = 0; i < 16; i = i + 1) begin
					infix[i] <= 7'b0000;
					postfix[i] <= 7'b0000;
					stack[i] <= 7'b0000;
					calc[i] <= 7'b0000;
				end
				valid <= 1'b0;
				input_flag <= 1'b0;
				result <= 7'd0;
				token_num <= 4'd0;
				infix_index <= 4'd0;
				postfix_index <= 4'd0;
				stack_index <= 4'd0;
				calc_index <= 4'd0;
            end
        endcase
		/*$display("\ntoken_num: %d", token_num);
		$write("infix: ");
		for(i = 0; i < 16; i = i + 1) $write("%d ", infix[i]);
		$display("\ninfix_index: %d", infix_index);
		$write("postfix: ");
		for(i = 0; i < 16; i = i + 1) $write("%d ", postfix[i]);
		$display("\npostfix_index: %d", postfix_index);
		$write("stack: ");
		for(i = 0; i < 16; i = i + 1) $write("%d ", stack[i]);
		$display("\nstack_index: %d", stack_index);
		$write("calc: ");
		for(i = 0; i < 16; i = i + 1) $write("%d ", calc[i]);
		$display("\ncalc_index: %d", calc_index);*/
    end
end

endmodule