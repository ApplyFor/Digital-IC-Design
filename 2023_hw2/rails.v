module rails(clk, reset, data, valid, result);

input        clk;
input        reset;
input  [3:0] data;
output       valid;
output       result;

reg    [3:0] number;
reg    [3:0] counter;
reg    [3:0] stack[0:9];
reg    [3:0] order[0:9];
reg    [3:0] pop_index;
reg    [3:0] top;
reg          valid;
reg          result;

integer i;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		number <= 0;
		counter <= 0;
		pop_index <= 0;
		top <= 0;
		valid <= 0;
		result <= 0;
        end
	else begin
		if (!number) begin
			number <= data;
		end
		else begin
			if (counter != number) begin
				stack[top] = counter+1;
				order[counter] = data;
				/*$write("stack: ");
				for(i=0;i<=top;i=i+1)	$write("%d", stack[i]);
				$write("\n");
				$write("order: ");
				for(i=0;i<=counter;i=i+1)	$write("%d", order[i]);
				$write("\n");*/
				counter = counter + 1;
				top = top + 1;

				while (stack[top-1] == order[pop_index]) begin
					if (top) begin
						top = top - 1;
						stack[top] = 0;
						pop_index = pop_index + 1;
					end
				end

				/*$write("stack: ");
				for(i=0;i<=top;i=i+1)	$write("%d", stack[i]);
				$write("\n");
				$write("order: ");
				for(i=0;i<=counter;i=i+1)	$write("%d", order[i]);
				$write("\n");*/
                	end
			else begin
				if (number > 0) begin
					valid <= 1;
					result <= top==0 ? 1 : 0;
				end
			end
		end
	end

	if (valid) begin
		valid <= 0;
		number <= 0;
		counter <= 0;
		pop_index <= 0;
		top <= 0;
	end
end

endmodule