module memory #(
    parameter INIT_FILE = "inital_board.txt",
    parameter BOARD_FILE = "board.txt",
    parameter WIDTH = 8,
    parameter DEPTH = 8,
    parameter DEPTH_LOG = $clog2(DEPTH)
)(
    input logic clk,
    input logic get, //boolean if we are writing
    input logic [8:0]address, //two digit hex value range 0-8
    input logic[2:0] pixel, // three digit binary representing collumn
    input logic write_data, //data written if get = false
    output logic[3:0] read_data//number of living cells surrounding
);

    //initializing addresses
    logic above_address = 8'hxx;
    logic below_address = 8'hxx;

    logic left_pixel = 3'bxxx;
    logic right_pixel = 3'bxxx;

    logic [WIDTH-1:0] board [0:DEPTH-1]; //initalizing 2d array board
    int [0:8] surrounding;

    initial if (INIT_FILE) begin //if it sends a file
        $readmemh(INIT_FILE, board, 0, DEPTH-1); //write the file to board
        $writememh(BOARD_FILE, board);
    end

    always_ff @(negedge get)begin
        board[address][pixel] <= write_data;
        $writememh(BOARD_FILE, board);
    end

    always_ff @(posedge get) begin
        //creating pixel wrap around
        if (pixel == 0) begin
            left_pixel  <= 3'b111;
            right_pixel <= pixel + 1;
        end
        else if (pixel == 7) begin
            left_pixel  <= pixel - 1;
            right_pixel <= 3'b000;
        end
        else begin
            left_pixel  <= pixel - 1;
            right_pixel <= pixel + 1;
        end

        //creating address wrap around
        if (address == 0) begin
            above_address <= 8'h07;
            below_address <= address + 8'h01;
        end
        else if (address == 7) begin
            above_address <= address - 8'h01;
            below_address <= 8'h00;
        end
        else begin
            above_address <= address - 8'h01;
            below_address <= address + 8'h01;
        end
        //getting words from board
        assign surrounding = {
            board[above_address][left_pixel:right_pixel],
            board[address][left_pixel:right_pixel],
            board[below_address][left_pixel:right_pixel]
            };
    end

    assign read_data = $countones(surrounding); // length of the array of all instances where the neighbor is alive


endmodule
