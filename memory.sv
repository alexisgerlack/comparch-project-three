module memory #(
    parameter str INIT_FILE = "",
    parameter int WIDTH = 3,
    parameter int DEPTH = 64,
    parameter DEPTH_LOG = $clog2(DEPTH)
)(
    input logic clk,
    input logic [2:0] read_address, //two bit hex address
    output logic [7:0] read_data //exports the intialized color data
);
    localparam LIVING = 1'b0;
    localparam DEAD =   1'b1;

    logic living_counter = 3'b000;
    logic [WIDTH-1:0] board [0 : DEPTH-1]; //initalizing 2d array board

    initial if (INIT_FILE) begin //if it sends a file
        $readmemh(INIT_FILE, board, 0, DEPTH-1); //write the file to board
    end

    always_ff @(posedge clk) begin
        read_data <= board[read_address]; //read the data and write it to read_data
    end

    //tallying adjacent living
    inital begin
        for(int i = 0; i <= 3, i=i+1)
            for(int j = 0; j < 3)
                if board[read_address + (8*i)+j] == LIVING)
                living_counter <= living_counter + 1;
    end

    always_comb @(posedge clk)begin
        case(state)
        LIVING:
            if (living_counter < 3'b011)//2+1 because it will be living
                state = DEAD;
        DEAD:
            if (living_counter == 3'b011)
                state = LIVING;
        end
    end

endmodule
