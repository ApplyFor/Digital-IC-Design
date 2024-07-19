module MPQ(clk,rst,data_valid,data,cmd_valid,cmd,index,value,busy,RAM_valid,RAM_A,RAM_D,done);
input clk;
input rst;
input data_valid;
input [7:0] data;
input cmd_valid;
input [2:0] cmd;
input [7:0] index;
input [7:0] value;
output reg busy;
output reg RAM_valid;
output reg [7:0]RAM_A;
output reg [7:0]RAM_D;
output reg done;


localparam
    reset    = 0,
    load     = 1,
    wait_cmd = 2,
    heapify  = 3,
    build    = 4,
    extract  = 5,
    insert   = 6,
    while_0  = 7,
    write    = 8;

reg[3:0] state, nxt_state, ret_state;
reg[7:0] A[0:255];
reg[7:0] num, build_i, left, right, largest;
reg[7:0] index_tmp;
reg[7:0] value_tmp;
reg is_insert;
wire [7:0] index_tmp_parent = index_tmp >> 1;
wire [7:0] RAM_A_plus2 = RAM_A + 2;
wire inc_continue = (index_tmp > 1) && (A[index_tmp_parent] < A[index_tmp]); //index > 1 and A[PARENT(index)] < A[index]

/*
MAX-HEAPIFY(A, i)
    l = 2 * i
    r = 2 * i + 1
    if l <= n and A[l] > A[i]
        largest = l
    else largest = i
    if r <= n and A[r] > A[largest]
        largest = r
    if largest != i
        exchange A[i] with A[largest]
        MAX-HEAPIFY(A, largest)

BUILD-QUEUE(A)
    for i = ⌊n/2⌋ downto 1
        MAX-HEAPIFY(A, i)

EXTRACT-MAX(A)
    if A.heap-size < 1
        error "heap underflow"
    max = A[1]
    A[1] = A[A.heap-size]
    A.heap-size = A.heap-size - 1
    MAX-HEAPIFY(A, 1)
    return max

INCREASE-VALUE(A, index, value)
    if value < A[index]
        error "new value is smaller than current value"
    A[index] = value
    while index > 1 and A[PARENT(index)] < A[index]
        exchange A[index] with A[PARENT(index)]
        index = PARENT(index)

INSERT-DATA(A, value)
    A.heap-size = A.heap-size + 1
    A[A.heap-size] = -∞
    INCREASE-VALUE(A, A.heap-size, value)
*/


always @(posedge clk, posedge rst)
    if(rst) state <= reset;
    else    state <= nxt_state;

always @(*) begin
    case(state)
        reset : nxt_state = load;
        load : begin
            if(!data_valid)
                nxt_state = wait_cmd;
            else
                nxt_state = load;
        end         
        wait_cmd : begin
            if(!cmd_valid)
                nxt_state = wait_cmd;
            else begin
                case(cmd)
                    0 : nxt_state = build; //Build_Queue
                    1 : nxt_state = extract; //Extract_Max
                    2 : nxt_state = insert; //Increase_Value
                    3 : nxt_state = insert; //Insert_Data
                    default : nxt_state = write; //Write
                endcase
            end
        end
        heapify : begin
            if(index_tmp == largest)
                nxt_state = ret_state; //back_state
            else
                nxt_state = heapify;
        end
        build : begin
            nxt_state = heapify;
        end
        extract : begin
            nxt_state = heapify;
        end
        insert : begin
            nxt_state = while_0;
        end
        while_0 : begin
            if(!inc_continue)
                nxt_state = wait_cmd;
            else //while index > 1 and A[PARENT(index)] < A[index]
                nxt_state = while_0;
        end
        default : begin
            if(RAM_A == num)
                nxt_state = reset;
            else
                nxt_state = write;
        end
    endcase
end

always @(*) begin // find max
    left = {index_tmp, 1'b0}; //l = 2 * i
    right = {index_tmp, 1'b1}; //r = 2 * i + 1
    largest = index_tmp;
    if((left <= num) && (A[left] > A[index_tmp])) //if l <= n and A[l] > A[i]
        largest = left; //largest = l
    if((right <= num) && (A[right] > A[largest])) //if r <= n and A[r] > A[largest]
        largest = right; //largest = r
end

always @(posedge clk) begin
    case(state)
        reset : begin
            A[1] <= data;
            num <= 1;
            RAM_valid <= 0;
            RAM_A     <= -1; // 8'hFF;
            done <= 0;
        end
        load : begin
            if(data_valid) begin
                num <= num + 1;
                A[num + 1] <= data;
            end
        end 
        wait_cmd : begin
            build_i <= (num >> 1);
            index_tmp <= index;
            value_tmp <= value;
            is_insert <= cmd[0];// increase : 010 insert : 011
        end 
        heapify : begin
            if(largest != index_tmp) begin //if largest != i
				//exchange A[i] with A[largest]
                A[index_tmp] <= A[largest];
                A[largest] <= A[index_tmp];
                index_tmp <= largest; //MAX-HEAPIFY(A, largest)
            end
        end 
        build : begin
			//for i = ⌊n/2⌋ downto 1
            index_tmp <= build_i;
            build_i <= build_i - 1;
            if(build_i == 1)
                ret_state <= wait_cmd;
            else
                ret_state <= build;
        end 
        extract : begin
            A[1] <= A[num]; //A[1] = A[A.heap-size]
            num <= num - 1; //A.heap-size = A.heap-size - 1
            index_tmp <= 1; //MAX-HEAPIFY(A, 1)
            ret_state <= wait_cmd;
        end 
        insert : begin
            if(is_insert) begin //Insert_Data
                num <= num + 1; //A.heap-size = A.heap-size + 1
                A[num + 1] <= value_tmp; //INCREASE-VALUE(A, A.heap-size, value)
                index_tmp <= num + 1; //INCREASE-VALUE(A, A.heap-size, value)
            end 
            else begin //Increase_Value
                A[index_tmp] <= value_tmp; //A[index] = value
            end
        end 
        while_0 : begin
            if(inc_continue) begin //while index > 1 and A[PARENT(index)] < A[index]
				//exchange A[index] with A[PARENT(index)]
                A[index_tmp_parent] <= A[index_tmp];
                A[index_tmp] <= A[index_tmp_parent];
                index_tmp <= index_tmp_parent; //index = PARENT(index)
            end
        end
        write : begin
            RAM_valid <= 1;
            RAM_A <= RAM_A + 1;
            RAM_D <= A[RAM_A_plus2]; //root : 1
            if(RAM_A == num) done <= 1;
        end 
    endcase
end

always @(posedge clk, posedge rst) begin
    if(rst) begin
        busy <= 0;
    end else begin
        if(nxt_state == wait_cmd)
            busy <= 0;
        else
            busy <= 1;
    end
end

endmodule

