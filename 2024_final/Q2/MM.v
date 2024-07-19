`timescale 1ns/10ps
module MM( in_data, col_end, row_end, ep,is_legal, out_data, rst, clk , change_row,valid,busy);
input           clk;
input           rst;
input           col_end;
input           row_end;
input      [7:0]     in_data;

output reg signed [31:0]   out_data;
output reg [2:0] ep;
output wire is_legal;
output reg change_row,valid,busy;

reg signed [7:0] mx1[15:0],mx2[15:0],mx3[15:0];
reg signed [16:0] temp_mx[15:0];
reg [3:0] mx1_row,mx2_row,mx3_row,mx1_col,mx2_col,mx3_col,cnt,mx1_col_cnt,mx1_row_cnt,mx2_col_cnt,mx2_row_cnt,mx3_col_cnt,mx3_row_cnt;
reg [3:0] temp_row_cnt,temp_col_cnt;
reg [3:0] last_col;
reg [4:0] cur,nxt;
reg to_next,mx1_error_flag,mx2_error_flag,mx3_error_flag;
integer i;

assign is_legal = (mx1_col == mx2_row && mx2_col == mx3_row && ep == 0  && (!(mx3_row > 1 && last_col != mx3_col))&& !mx3_error_flag);
wire signed [15:0] temp_sum1 = mx1[mx1_row_cnt * mx1_col + mx1_col_cnt] * mx2[mx2_row_cnt * mx2_col + mx2_col_cnt];
wire signed [31:0] temp_sum2 = temp_mx[temp_row_cnt * mx2_col + temp_col_cnt] * mx3[mx3_row_cnt * mx3_col + mx3_col_cnt];

parameter 
load_mx1 = 0,
load_mx2 = 1,
load_mx3 = 2,
calculate1 = 3,
hold1 = 4,
calculate2 = 5,
hold2 = 6,
not_legal = 7,
finish = 8;

always @(*) begin
    case(cur)
        load_mx1:nxt = (to_next)?load_mx2:load_mx1;
        load_mx2:nxt = (to_next)?load_mx3:load_mx2;
        load_mx3:nxt = (to_next)?(is_legal)?calculate1:not_legal:load_mx3;
        calculate1:nxt = ((mx1_col_cnt == mx1_col-1 && mx1_row_cnt == mx1_row-1) &&(mx2_col_cnt == mx2_col-1 && mx2_row_cnt == mx2_row-1))?hold2:(mx1_col_cnt == mx1_col - 1)?hold1:calculate1;
        calculate2:nxt = ((temp_col_cnt == mx2_col-1 && temp_row_cnt == mx1_row-1) &&(mx3_col_cnt == mx3_col-1 && mx3_row_cnt == mx3_row-1))?finish:(temp_col_cnt == mx2_col - 1)?hold2:calculate2;
        hold1:nxt = calculate1;
        hold2:nxt = calculate2;
		not_legal:nxt = finish;
        finish:nxt = load_mx1;
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        cur <= load_mx1;
        mx1_row <= 0;
        mx2_row <= 0;
		mx3_row <= 0;
        mx1_col <= 0;
        mx2_col <= 0;
		mx3_col <= 0;
        cnt <= 0;
        mx1_row_cnt <= 0;
        mx1_col_cnt <= 0;
        mx2_row_cnt <= 0;
        mx2_col_cnt <= 0;
		mx3_row_cnt <= 0;
		mx3_col_cnt <= 0;
		temp_row_cnt <= 0;
		temp_col_cnt <= 0;
		for(i = 0; i < 16; i = i + 1) temp_mx[i] <= 0;
        out_data <= 0;
        valid <= 0;
        busy <= 0;
		to_next <= 0;
		mx1_error_flag <= 0;
		mx2_error_flag <= 0;
		mx3_error_flag <= 0;
		ep <= 0;
    end
    else begin
        cur <= nxt;
        case (cur)
            load_mx1:begin
                mx1[cnt] <= in_data;
                if(mx1_row > 1 && last_col != mx1_col)mx1_error_flag <= 1;
                if(col_end)begin
                    mx1_col <= mx1_col_cnt + 1;
                    last_col <= mx1_col; //check every column
                    mx1_row <= mx1_row + 1;
                    mx1_col_cnt <= 0;
                end
                else mx1_col_cnt <= mx1_col_cnt + 1;
                if(row_end)begin
                    to_next <= 1;
                    busy <= 1;
                end
                else begin
                    if(to_next)begin //check last column
                        cnt <= 0;
                        to_next <= 0;
                        busy <= 0;
                    end
                    else cnt <= cnt + 1;
                end
            end
            load_mx2:begin
                if(mx1_error_flag)ep <= ep + 1;
                mx1_error_flag <= 0;
                mx2[cnt] <= in_data;
                if(mx2_row > 1 && last_col != mx2_col)mx2_error_flag <= 1;
                if(col_end)begin
                    mx2_col <= mx2_col_cnt + 1;
                    last_col <= mx2_col;
                    mx2_row <= mx2_row + 1;
                    mx2_col_cnt <= 0;
                end
                else mx2_col_cnt <= mx2_col_cnt + 1;

                if(row_end)begin
                    to_next <= 1;
                    busy <= 1;
                end
                else begin
                    if(to_next)begin
                        cnt <= 0;
                        to_next <= 0;
                        busy <= 0;
                    end
                    else cnt <= cnt + 1;
                end
            end
            load_mx3:begin
                if(mx2_error_flag)ep <= ep + 2;
                mx2_error_flag <= 0;
                mx3[cnt] <= in_data;
                if(mx3_row > 1 && last_col != mx3_col)mx3_error_flag <= 1;
                if(col_end)begin
                    mx3_col <= mx3_col_cnt + 1;
                    last_col <= mx3_col;
                    mx3_row <= mx3_row + 1;
                    mx3_col_cnt <= 0;
                end
                else mx3_col_cnt <= mx3_col_cnt + 1;

                if(row_end)begin
                    to_next <= 1;
                    busy <= 1;
                end
                else begin
                    if(to_next)begin
                        cnt <= 0;
                        to_next <= 0;
                        mx1_col_cnt <= 0;
                        mx2_col_cnt <= 0;
                        mx3_col_cnt <= 0;
                        mx1_row_cnt <= 0;
                        mx2_row_cnt <= 0;
                        mx3_row_cnt <= 0;
                    end
                    else cnt <= cnt + 1;
                end
            end
            calculate1:begin
                temp_mx[cnt] <= temp_mx[cnt] + temp_sum1;
                if(mx2_col_cnt == mx2_col-1 && mx2_row_cnt == mx2_row-1)change_row <= 1;
                else change_row <= 0;

                if(mx2_row_cnt == mx2_row -1 && mx2_col_cnt == mx2_col -1)begin
                    mx2_row_cnt <= 0;
                    mx2_col_cnt <= 0;
                    mx1_row_cnt <= mx1_row_cnt + 1;
                end
                else if(mx2_row_cnt == mx2_row -1)begin
                    mx2_col_cnt <= mx2_col_cnt + 1;
                    mx2_row_cnt <= 0;
                end
                else begin
                    mx2_row_cnt <= mx2_row_cnt + 1;
                end

                if(mx1_col_cnt == mx1_col -1)begin
                    mx1_col_cnt <= 0;
                end
                else mx1_col_cnt <= mx1_col_cnt + 1;
            end
            hold1:begin
				cnt <= cnt + 1;
            end
			calculate2:begin
				out_data <= out_data + temp_sum2;
				if(mx3_col_cnt == mx3_col-1 && mx3_row_cnt == mx3_row-1)change_row <= 1;
                else change_row <= 0;

                if(mx3_row_cnt == mx3_row -1 && mx3_col_cnt == mx3_col -1)begin
                    mx3_row_cnt <= 0;
                    mx3_col_cnt <= 0;
                    temp_row_cnt <= temp_row_cnt + 1;
                    valid = 1;
                end
                else if(mx3_row_cnt == mx3_row -1)begin
                    mx3_col_cnt <= mx3_col_cnt + 1;
                    mx3_row_cnt <= 0;
                    valid = 1;
                end
                else begin
                    mx3_row_cnt <= mx3_row_cnt + 1;
                end

                if(temp_col_cnt == mx2_col -1)begin
                    temp_col_cnt <= 0;
                end
                else temp_col_cnt <= temp_col_cnt + 1;
            end
            hold2:begin
				if(cnt) begin
					cnt <= 0;
				end
				else begin
					out_data <= 0;
					valid <= 0;
				end
            end
            not_legal:begin
                if(mx3_error_flag)ep <= ep + 4;
                mx3_error_flag <= 0;
                valid <= 1;
            end
            finish:begin
                valid <= 0;
                mx1_row <= 0;
                mx2_row <= 0;
                mx3_row <= 0;
                mx1_col <= 0;
                mx2_col <= 0;
                mx3_col <= 0;
                cnt <= 0;
                mx1_row_cnt <= 0;
                mx1_col_cnt <= 0;
                mx2_row_cnt <= 0;
                mx2_col_cnt <= 0;
                mx3_row_cnt <= 0;
                mx3_col_cnt <= 0;
				temp_row_cnt <= 0;
				temp_col_cnt <= 0;
				for(i = 0; i < 16; i = i + 1) temp_mx[i] <= 0;
                out_data <= 0;
                busy <= 0;
                to_next <= 0;
                mx1_error_flag <= 0;
                mx2_error_flag <= 0;
                mx3_error_flag <= 0;
                ep <= 0;
            end
        endcase
    end
end
endmodule