`include "get.sv"
`include "store.sv"
`include "ws2812b.sv"
`include "controller.sv"
// game of life top level module
module top(
    input logic     clk,
    output logic    _48b,
    output logic    _45a
);
    localparam WIDTH = 8;
    localparam DEPTH = 8;
    localparam [23:0] ALIVE_GRB = 24'h100008; //GRB color of alive cell
    parameter FRAMES = 16; //led frames per step of each life gen .5 seconds ish

    logic transmit_pixel;
    logic shift;
    logic ws2812b_out;
    logic get;
    logic store;
    logic [23:0] shift_reg;
    logic load_pixel_count;
    logic [5:0] pixel;
    logic [4:0] frame; //16 frames so 4 bit
    logic [4:0] frame_q = 24'd0;
    logic [WIDTH*DEPTH-1:0] board;

    always_ff @(posedge clk) frame_q <= frame;
    assign get = (frame != frame_q) && (frame == 0||frame ==16); //fires at 0 and 16 frames
    // Instance of the simulation
    get #(
        .INIT_FILE      ("inital_board.txt"),
        .BOARD_FILE     ("board.txt")
    ) u1 (
        .clk            (clk),
        .get            (get),
        .new_board      (board),
        .store          (store)
    );
    //storing simulation to file
    store #(
        .BOARD_FILE("board.txt")
    ) u2 (
        .clk            (clk),
        .store          (store),
        .new_board      (board)
    );

    //load color shift to MSB
    always_ff @(posedge clk)begin
        if (load_pixel_count)
            shift_reg <= (board[pixel]) ? ALIVE_GRB : 24'd0;
        else if (shift)
            shift_reg <={shift_reg[22:0], 1'b0};
    end
    // Instance the WS2812B output driver
    ws2812b u4 (
        .clk            (clk),
        .serial_in      (shift_reg[23]),
        .transmit       (transmit_pixel),
        .ws2812b_out    (ws2812b_out),
        .shift          (shift)
    );

    // Instance the controller
    controller u5 (
        .clk            (clk),
        .load_sreg      (load_pixel_count),
        .transmit_pixel (transmit_pixel),
        .pixel          (pixel),
        .frame          (frame)
    );

    assign _48b = ws2812b_out; //send the data
    assign _45a = ~ws2812b_out; // send the data

endmodule
