module get #(
    parameter INIT_FILE = "inital_board.txt",
    parameter BOARD_FILE = "board.txt",
    parameter WIDTH = 8,
    parameter DEPTH = 8,
    parameter DEPTH_LOG = $clog2(DEPTH)
)(
    input logic clk,
    input logic get, //boolean update
    output logic store, //boolean update
    output logic [WIDTH*DEPTH-1:0] board //new board
);

    //initializing addresses
    logic [7:0] above_address = 8'hxx;
    logic [7:0] below_address = 8'hxx;
    logic [7:0] iterate_address = 8'hxx; //iterable logic


    logic [2:0] left_pixel = 3'bxxx;
    logic [2:0] right_pixel = 3'bxxx;
    logic [3:0] iterate_pixel = 4'bxxxx; //iterable logic

    logic [WIDTH-1:0] rows [0:DEPTH-1]; //initalizing 2d array board
    logic [WIDTH-1:0] new_board [0:DEPTH-1]; //initializing new board
    logic [3:0] alive_count;


    initial if (INIT_FILE) begin //if it sends a file
        $readmemb(INIT_FILE, rows, 0, DEPTH-1); //write the file to board
`ifndef SYNTHESIS //only if we are not synthesizing
        $writememb(BOARD_FILE, rows);
`endif
    end

    always_comb //converts the array rows to a single 64 bit vector board
        for (int i = 0; i< DEPTH; i++)
            board[i*WIDTH +:WIDTH] = rows[i];


    always @(posedge clk) begin
        store <= get; //this is a deliberate use of non-blocking
        for (iterate_address = 0; iterate_address < 8 ; iterate_address++) begin//loop 8x
            //creating address wrap around
            if (iterate_address == 0) begin
                above_address = 8'h07;
                below_address = iterate_address + 8'h01;
            end
            else if (iterate_address == 7) begin
                above_address = iterate_address - 8'h01;
                below_address = 8'h00;
            end
            else begin
                above_address = iterate_address - 8'h01;
                below_address = iterate_address + 8'h01;
            end
            for (iterate_pixel = 0; iterate_pixel < 8 ; iterate_pixel++) begin//loop 8x
                //creating pixel wrap around
                if (iterate_pixel == 0) begin
                    left_pixel  = 3'b111;
                    right_pixel = iterate_pixel + 1;
                end
                else if (iterate_pixel == 7) begin
                    left_pixel  = iterate_pixel - 1;
                    right_pixel = 3'b000;
                end
                else begin
                    left_pixel  = iterate_pixel - 1;
                    right_pixel = iterate_pixel + 1;
                end

                //summing surrounding alive pixels minus self
                alive_count =
                    rows[above_address][left_pixel] + rows[above_address][iterate_pixel] + rows[above_address][right_pixel] +
                    rows[iterate_address][left_pixel] + rows[iterate_address][right_pixel] +
                    rows[below_address][left_pixel] + rows[below_address][iterate_pixel] + rows[below_address][right_pixel];

                //determining new value
                if (rows[iterate_address][iterate_pixel] == 1)begin
                    if (alive_count < 2 | alive_count > 3)
                        //if less than 2 or more than 3 its dead
                        new_board[iterate_address][iterate_pixel] = 0;
                    else
                        //if 2-3 its alive
                        new_board[iterate_address][iterate_pixel] = 1;
                end
                else if (alive_count == 3)
                    //if dead and three its alive
                    new_board[iterate_address][iterate_pixel] = 1;
                else
                    //if dead and not three its dead
                    new_board[iterate_address][iterate_pixel] = 0;
            end

        end
        if(get)
            for (int i = 0; i < DEPTH; i++)
                rows[i] = new_board[i]; //changing the old board to the new one
    end

endmodule
