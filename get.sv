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
    output logic [WIDTH*DEPTH-1:0] new_board //packed board
);

    //initializing addresses
    logic [7:0] above_address = 8'hxx;
    logic [7:0] below_address = 8'hxx;
    logic [7:0] iterate_address = 8'hxx; //iterable logic

    logic [2:0] left_pixel = 3'bxxx;
    logic [2:0] right_pixel = 3'bxxx;
    logic [3:0] iterate_pixel = 4'bxxxx; //iterable logic

    logic [WIDTH-1:0] rows [0:DEPTH-1]; //initalizing 2d array board
    logic [WIDTH-1:0] next_rows [0:DEPTH-1]; //initializing new board

    logic [3:0] alive_count;


    initial if (INIT_FILE) begin //if it sends a file
        $readmemb(INIT_FILE, rows, 0, DEPTH-1); //write the file to board
`ifndef SYNTHESIS //only if we are not synthesizing
        $writememb(BOARD_FILE, rows);
`endif
    end

    always_comb //converts the array rows to a single 64 bit packed vector board
        for (int i = 0; i< DEPTH; i++)
            new_board[i*WIDTH +:WIDTH] = rows[i];

    //new gen
    always @(posedge clk) begin
        for (iterate_address = 0; iterate_address < DEPTH ; iterate_address++) begin//loop 8x
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
            for (iterate_pixel = 0; iterate_pixel < WIDTH ; iterate_pixel++) begin//loop 8x
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

                //extending to 4 bits and summing surrounding alive pixels minus self
                alive_count =
                    {3'b0, rows[above_address][left_pixel]}    + //top left
                    {3'b0, rows[above_address][iterate_pixel]} + //top mid
                    {3'b0, rows[above_address][right_pixel]}   + //top right
                    {3'b0, rows[iterate_address][left_pixel]}  + //mid left
                    {3'b0, rows[iterate_address][right_pixel]} + //mid right
                    {3'b0, rows[below_address][left_pixel]}    + //bottom left
                    {3'b0, rows[below_address][iterate_pixel]} + //bottom mid
                    {3'b0, rows[below_address][right_pixel]}   ; //bottom right

                //determining new value
                if (rows[iterate_address][iterate_pixel] == 1)begin
                    //if less than 2 or more than 3 its dead
                    //if 2-3 its alive
                    next_rows[iterate_address][iterate_pixel] = (alive_count < 2 || alive_count > 3) ? 1'b0 : 1'b1;
                end
                else
                    next_rows[iterate_address][iterate_pixel] = (alive_count == 3) ? 1'b1 : 1'b0;
            end

        end
    end
    always_ff @(posedge clk) begin
        store <= get;

        if (get) begin
            for (int i = 0; i < DEPTH; i++)begin
                rows[i] <= next_rows[i]; //changing the old board to the new one
`ifndef SYNTHESIS //only if we are not synthesizing
                $writememb(BOARD_FILE, rows);
`endif
            end
        end

    end

endmodule
