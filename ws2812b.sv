module ws2812b(
    input logic clk,
    input logic serial_in, //data being sent
    input logic transmit, //boolean whether we are transmitting the data
    output logic ws2812b_out, // what is sent
    output logic shift // boolean if this clock tick we are changing from idle
);

    localparam IDLE = 1'b0;
    localparam TRANSMITTING = 1'b1;

    localparam T0_CYCLE_COUNT = 4'd5;
    localparam T1_CYCLE_COUNT = 4'd10;
    localparam MAX_CYCLE_COUNT = 4'd15;

    logic state = IDLE;
    logic [3:0] cycle_count = 4'd0;
    logic bit_being_sent = 1'b0;

    always_ff @(posedge clk) begin
        unique case (state)
            IDLE:
                if (transmit == 1'b1) begin //if transmit = true:
                    state <= TRANSMITTING; //change state
                    cycle_count <= 4'd0; //reset cycle count
                    bit_being_sent <= serial_in; //send the data
                end
            TRANSMITTING:
                if (transmit == 1'b0) begin //if transmit = false
                    state <= IDLE; //change state
                end
                else if (cycle_count == MAX_CYCLE_COUNT - 1) begin //if we do too many cycles
                    cycle_count <= 4'd0; //reset cycle count
                    bit_being_sent <= serial_in; //send the data
                end
                else begin
                    cycle_count <= cycle_count + 1; //if its not too many cycles do another one
                end
        endcase
    end

    always_comb begin
        if (state == TRANSMITTING) // if we are changing from transmitting to idle
            if (bit_being_sent == 1'b0) // and we are sending zero
                ws2812b_out = (cycle_count < T0_CYCLE_COUNT); //i dont understand this part but i know its converting the data
            else
                ws2812b_out = (cycle_count < T1_CYCLE_COUNT);
        else
            ws2812b_out = 1'b0; //if we are not transmitting zero
    end

    assign shift = (state == TRANSMITTING) && (cycle_count == 4'd0); //are we changing from idle

endmodule
