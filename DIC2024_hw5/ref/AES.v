// 
// Designer: P76111783
//
module AES(
    input clk,
    input rst,
    input [127:0] P,
    input [127:0] K,
    output reg [127:0] C,
    output reg valid
    );

// write your design here //
wire [127:0] state_array[0:10];
wire [127:0] key[0:9];
reg [127:0] register_S[0:9];
reg [127:0] register_K[0:9];
reg [7:0] cycle;
genvar i;
integer r;

AddRoundKey ARK1(.s(P), .k(K), .s_(state_array[0]));
KeyExpansion SubKey1(.round(4'd1), .k(K), .k_(key[0]));
generate
        for(i = 1; i <= 10; i = i + 1) begin: AES_round
            if(i!=10) begin
                RoundTwoFive R19(.plain(register_S[i-1]), .key(register_K[i-1]), .cipher(state_array[i]));
                KeyExpansion SubKey(.round(i[3:0]+4'd1), .k(register_K[i-1]), .k_(key[i]));
            end
            else RoundTwoFour R10(.plain(register_S[i-1]), .key(register_K[i-1]), .cipher(state_array[i]));
        end
endgenerate

always @(posedge clk or posedge rst) begin
    if (rst) begin
        C <= 0;
        valid <= 0;
        for(r = 0; r < 10; r = r + 1) begin
        	register_S[r] <= 0;
           	register_K[r] <= 0;
        end
        cycle <= 0;
    end
    else begin
		for(r = 0; r < 10; r = r + 1) begin
				register_S[r] <= state_array[r];
				register_K[r] <= key[r];
		end

        C <= state_array[10];
        valid <= (cycle > 10) ? 1'd1 : 1'd0;
        cycle <= (cycle < 255) ? cycle + 8'd1 : cycle;
    end
end
endmodule