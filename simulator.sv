`include "memory.sv"

module simulator #(
    parameter INIT_FRAME = ""
)(
    input logic clk,
    input logic current_state,
    input logic pixel_row[2:0], //pixel row
    input logic pixel_collumn[2:0], //pixel collumn
    input logic current_board, //current board
    output logic state
);
    localparam LIVING = 1'b0;
    localparam DEAD =   1'b1;

    logic living_counter = 3'b000;

    //tallying adjacent living
    inital begin
        for(int i = 0; i < 3, i=i+1)
            for(int j = 0; j < 3)
                if (current_board[(pixel_row -1 +i) (pixel_collumn -1 +j)] == LIVING)
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
