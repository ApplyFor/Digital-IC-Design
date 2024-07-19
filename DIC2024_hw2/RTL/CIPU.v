module CIPU(
input       clk, 
input       rst,
input       [7:0]people_thing_in,
input       ready_fifo,
input       ready_lifo,
input       [7:0]thing_in,
input       [3:0]thing_num,
output reg     valid_fifo,
output reg     valid_lifo,
output reg     valid_fifo2,
output reg     [7:0]people_thing_out,
output reg     [7:0]thing_out,
output reg     done_thing,
output reg     done_fifo,
output reg     done_lifo,
output reg     done_fifo2);

localparam SESSION_IN = 3'd0;
localparam PASSENGER_POP = 3'd1;
localparam THING_POP1 = 3'd2;
localparam THING_POP2 = 3'd3;
localparam RESTART = 3'd4;
localparam STAY = 3'd5;
localparam OUT = 3'd6;
localparam WAIT = 3'd7;

reg [2:0] state_fifo, nextState_fifo;
reg [2:0] state_lifo, nextState_lifo;
reg [4:0] people_num;
reg [4:0] people_index;
reg [4:0] stack_num;
reg [4:0] pop_num;
reg [4:0] thing_index;
reg [7:0] people[15:0]; //passenger(FIFO)
reg [7:0] thing[15:0]; //baggage(LIFO)

integer i;

always@(posedge clk or posedge ready_fifo) begin
	case(state_fifo)
		SESSION_IN:begin
			if (people_thing_in == 36) nextState_fifo = PASSENGER_POP; //$
			else nextState_fifo = SESSION_IN;
        end
		PASSENGER_POP:begin
			if (people_num == 0) nextState_fifo = WAIT;
            else nextState_fifo = OUT;
		end
        OUT:begin
			if (people_num == people_index+1) nextState_fifo = WAIT;
			else nextState_fifo = OUT;
        end
		default:begin
            nextState_fifo = SESSION_IN;
        end
	endcase
end	

always @(posedge clk) begin
    if(rst || ready_fifo) state_fifo <= SESSION_IN;
    else state_fifo <= nextState_fifo;
end

always @(posedge clk or posedge ready_fifo) begin
    if(rst || ready_fifo)begin
		for(i = 0; i < 16; i = i + 1) people[i] <= 7'b1111111;
		valid_fifo <= 0;
		done_fifo <= 0;
		people_num <= 0;
		people_index <= 0;
    end
	else begin
        case(state_fifo)
            SESSION_IN:begin
				//$display("session:  %c", people_thing_in);
				//$display("people: ");  
				//for(i = 0; i < 16; i = i + 1) $write("%c ", people[i]);
				//$display("");  
				people[people_index] <= people_thing_in;
				if(people_thing_in>=65 && people_thing_in<=90) people_index <= people_index+1; //A~Z
				else if (people_thing_in == 36) people_num<=people_index;
				else people_index <= people_index;
            end
			PASSENGER_POP:begin
				//$display("num: %d", people_num);
				people_index <= 0;
			end
			OUT:begin//output result
				//$display("index: %d", people_index);
				valid_fifo <= 1;
				people_thing_out <= people[people_index];
				people_index <= people_index+1;
			end
			WAIT:begin//reset register
                for(i = 0; i < 16; i = i + 1) people[i] <= 7'b1111111;
				valid_fifo <= 0;
				done_fifo <= 1;
				people_num <= 0;
				people_index <= 0;
            end
		endcase
	end
end

//====================================================================================================

always@(posedge clk or posedge ready_lifo) begin
	case(state_lifo)
		SESSION_IN:begin
			if (thing_in == 59) nextState_lifo = THING_POP1; //;
			else if (thing_in == 36) nextState_lifo = THING_POP2; //$
			else nextState_lifo = SESSION_IN;
        end
		THING_POP1:begin
			if (thing_num == pop_num+1 || thing_num == 0) nextState_lifo = RESTART;
            else nextState_lifo = THING_POP1;
		end
		RESTART:begin
			nextState_lifo = STAY;
		end
		STAY:begin
			nextState_lifo = SESSION_IN;
		end
		THING_POP2:begin
			if (stack_num == 0) nextState_lifo = WAIT;
            else nextState_lifo = OUT;
		end
        OUT:begin
			if (stack_num == thing_index+1) nextState_lifo = WAIT;
			else nextState_lifo = OUT;
        end
		default:begin
            nextState_lifo = SESSION_IN;
        end
	endcase
end	

always @(posedge clk) begin
    if(rst || ready_lifo) state_lifo <= SESSION_IN;
    else state_lifo <= nextState_lifo;
end

always@(posedge clk or posedge ready_lifo) begin
    if(rst || ready_lifo)begin
		for(i = 0; i < 16; i = i + 1) thing[i] <= 7'b1111111;
		valid_lifo <= 0;
		valid_fifo2 <= 0;
		done_thing <= 0;
		done_lifo <= 0;
		done_fifo2 <= 0;
		stack_num <= 0;
		pop_num <= 0;
		thing_index <= 0;
    end
	else begin
		//$display("thing_index: %d", thing_index);
		case(state_lifo)
			SESSION_IN:begin
				//$display("session:  %c", thing_in);
				//$display("thing: ");  
				//for(i = 0; i < 16; i = i + 1) $write("%c ", thing[i]);
				//$display("");
				pop_num <= 0;
				thing[thing_index] <= thing_in;
				if(thing_in>=48 && thing_in<=57) thing_index <= thing_index+1; //0~9
				else if (thing_in == 36) stack_num <= thing_index; //$
				else thing_index <= thing_index;
			end
			THING_POP1:begin
				//$display("pop num: %d", thing_num);
				valid_lifo <= 1;
				if(thing_num == 0) begin
					thing_out <= 48; //0
				end
				else begin
					thing_out <= thing_index == 0 ? thing[thing_index] : thing[thing_index-1];
					thing_index <= thing_index == 0 ? thing_index : thing_index-1;
					pop_num <= pop_num+1;
				end
			end
			RESTART:begin
				valid_lifo <= 0;
				done_thing <= 1;
			end
			STAY:begin
				done_thing <= 0;
			end
			THING_POP2:begin
				//display("stack num: %d", stack_num);
				thing_index <= 0;
				done_lifo <= 1;
			end
			OUT:begin//output result
				//$display("index: %d", thing_index);
				valid_fifo2 <= 1;
				done_lifo <= 0;
				thing_out <= thing[thing_index];
				thing_index <= thing_index+1;
			end
			WAIT:begin//reset register
				for(i = 0; i < 16; i = i + 1) thing[i] <= 7'b1111111;
				valid_lifo <= 0;
				valid_fifo2 <= 0;
				done_thing <= 0;
				done_lifo <= 0;
				done_fifo2 <= 1;
				stack_num <= 0;
				pop_num <= 0;
				thing_index <= 0;
            end
		endcase
	end
end	

endmodule