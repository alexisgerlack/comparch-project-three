module controller (
    input logic clk,
    output logic load_sreg,
    output logic transmit_pixel,
    output logic [5:0] pixel,//the pixel we are assigning
    output logic [4:0] frame//in what frame
);

    localparam TRANSMIT_FRAME       = 1'b0;
    localparam IDLE                 = 1'b1;

    localparam [2:0] READ_CH_VALS   = 3'b001;
    localparam [2:0] LOAD_SREG      = 3'b010;
    localparam [2:0] TRANSMIT_PIXEL = 3'b100;

    localparam [8:0] TRANSMIT_CYCLES    = 9'd360;       // = 24 bits / pixel x 15 cycles / bit
    localparam [19:0] IDLE_CYCLES       = 20'd351832;   // = 375000 - 64 x (360 + 2) for 32 frames /second

    logic state = TRANSMIT_FRAME;
    logic next_state;

    logic [2:0] transmit_phase = READ_CH_VALS;
    logic [2:0] next_transmit_phase;

    logic [5:0] pixel_counter = 6'd0;
    logic [4:0] frame_counter = 5'd0;
    logic [8:0] transmit_counter = 9'd0;
    logic [19:0] idle_counter = 20'd0;

    logic transmit_pixel_done;
    logic idle_done;

    assign transmit_pixel_done = (transmit_counter == TRANSMIT_CYCLES - 1); //are we done
    assign idle_done = (idle_counter == IDLE_CYCLES - 1); // are we done

    always_ff @(negedge clk) begin
        state <= next_state;
        transmit_phase <= next_transmit_phase;
    end

    //Next state logic
    always_comb begin
        next_state = 1'bx; //reset next state logic
        unique case (state)
            TRANSMIT_FRAME:
                //if we are on the last pixel and we are done transmitting
                next_state = ((pixel_counter == 6'd63) && (transmit_pixel_done)) ? IDLE : TRANSMIT_FRAME;
            IDLE:
                next_state = (idle_done) ? TRANSMIT_FRAME : IDLE;
        endcase
    end

    always_comb begin
        next_transmit_phase = READ_CH_VALS;
        if (state == TRANSMIT_FRAME) begin
            case (transmit_phase)
                READ_CH_VALS:
                    next_transmit_phase = LOAD_SREG;
                LOAD_SREG:
                    next_transmit_phase = TRANSMIT_PIXEL;
                TRANSMIT_PIXEL:
                    next_transmit_phase = transmit_pixel_done ? READ_CH_VALS : TRANSMIT_PIXEL;
            endcase
        end
    end

    always_ff @(negedge clk) begin
        if ((state == TRANSMIT_FRAME) && transmit_pixel_done) begin
            pixel_counter <= pixel_counter + 1;//if we are transmitting the pixel switch to the next
        end

        if (idle_done) begin //if we are done idling
            frame_counter <= frame_counter + 1;//move to the next frame
        end

        //if we r trasmitting pixels continue else reset
        transmit_counter <= (transmit_phase == TRANSMIT_PIXEL) ? transmit_counter + 1 : 9'd0;

        //if we r idling wait, else reset
        idle_counter <= (state) ? idle_counter + 1 : 20'd0;
    end

    assign pixel = pixel_counter;
    assign frame = frame_counter;

    assign load_sreg = (transmit_phase == LOAD_SREG);
    assign transmit_pixel = (transmit_phase == TRANSMIT_PIXEL);

endmodule
