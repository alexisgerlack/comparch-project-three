module store #(
    parameter BOARD_FILE = "board.txt",
    parameter WIDTH = 8,
    parameter DEPTH = 8
)(
    input logic clk,
    input logic store, //boolean
    input logic [WIDTH*DEPTH-1:0] new_board //data written
);
`ifndef SYNTHESIS //only exists in sim
    logic [WIDTH-1:0] rows [0:DEPTH-1];

    always @(posedge store)begin
        //writing new_board file to board.txt
        for (int i=0; i < DEPTH; i++)
            rows[i] = board[i*WIDTH : WIDTH]; //turning each row into a single 64-bit vector

        $writememb(BOARD_FILE, rows);
    end
`endif
endmodule
