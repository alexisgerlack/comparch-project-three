`include "memory.sv"
`include "ws2812b.sv"
`include "controller.sv"

// led_matrix top level module

module top(
    input logic     clk,
    input logic     SW,
    input logic     BOOT,
    output logic    _48b,
    output logic    _45a
);

    logic [7:0] pixel;
    logic [8:0] address;

    logic transmit_pixel;
    logic shift;
    logic ws2812b_out;

    assign address = { pixel };

    // Instance sample memory for red channel
    memory #(
        .INIT_FILE      ("inital_board.txt")
    ) u1 (
        .clk            (clk),
        .read_address   (address),
        .read_data      (data)
    );

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
        .load_sreg      (load_sreg),
        .transmit_pixel (transmit_pixel),
        .pixel          (pixel),
        .frame          (frame)
    );
    
    assign _48b = ws2812b_out; //send the data
    assign _45a = ~ws2812b_out; // send the data

endmodule
