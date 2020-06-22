// D-PHY (CIL-SFNN) receiver that can only do HS RX.
// Why? Some FPGAs have MIPI lines connected to a single port.
// This means you can only pick one IO standard: HSTL 1.2V for LP RX or LVDS for HS RX.
// LVDS is picked, and though this doesn't technically comply with D-PHY, it should work.
// This means the protocol layer should send a reset after receiving the last byte.
// https://www.intel.com/content/www/us/en/programmable/documentation/mcn1446711751001.html#mcn1448380606073
module d_phy_receiver #(
    // Gives the receiver resistance to noise by expecting 0s before a sync sequence
    parameter int ZERO_ACCUMULATOR_WIDTH = 3
) (
    input logic clock_p,
    input logic data_p,
    // Synchronous reset
    // D-PHY clocks for TCLK-POST after the HS RX ends so this will stick
    input logic reset,
    // Output byte
    output logic [7:0] data,
    // Whether the output byte is valid
    output logic enable
);

logic dataout_h = 1'd0, dataout_l = 1'd0;

always_ff @(posedge clock_p) dataout_h <= data_p;
always_ff @(negedge clock_p) dataout_l <= data_p;

logic [8:0] internal_data = 9'd0;

always_ff @(posedge clock_p)
    internal_data <= {dataout_l, dataout_h, internal_data[8:2]}; // "Each byte shall be transmitted least significant bit first."

localparam bit [1:0] STATE_UNKNOWN = 2'd0;
localparam bit [1:0] STATE_SYNC_IN_PHASE = 2'd1;
localparam bit [1:0] STATE_SYNC_OUT_OF_PHASE = 2'd2;
logic [1:0] state = STATE_UNKNOWN;

assign data = state == STATE_SYNC_IN_PHASE ? internal_data[7:0] : state == STATE_SYNC_OUT_OF_PHASE ? internal_data[8:1] : 8'dx;

// Byte counter
logic [1:0] counter = 2'd0;

assign enable = state != STATE_UNKNOWN && counter == 2'd0;

logic [ZERO_ACCUMULATOR_WIDTH-1:0] zero_accumulator = ZERO_ACCUMULATOR_WIDTH'(0);
always_ff @(posedge clock_p)
begin
    if (internal_data[1] || internal_data[0])
        zero_accumulator <= ZERO_ACCUMULATOR_WIDTH'(0);
    else if (zero_accumulator + 1'd1 == ZERO_ACCUMULATOR_WIDTH'(0))
        zero_accumulator <= zero_accumulator;
    else
        zero_accumulator <= zero_accumulator + 1'd1;
end

always_ff @(posedge clock_p)
begin
    if (reset)
    begin
        state <= STATE_UNKNOWN;
        counter <= 2'dx;
    end
    else
    begin
        if (state == STATE_UNKNOWN)
        begin
            if (internal_data == 9'b101110000 && zero_accumulator + 1'd1 == ZERO_ACCUMULATOR_WIDTH'(0))
            begin
                state <= STATE_SYNC_OUT_OF_PHASE;
                counter <= 2'd3;
            end
            else if (internal_data[7:0] == 8'b10111000 && zero_accumulator + 1'd1 == ZERO_ACCUMULATOR_WIDTH'(0))
            begin
                state <= STATE_SYNC_IN_PHASE;
                counter <= 2'd3;
            end
            else
            begin
                state <= STATE_UNKNOWN;
                counter <= 2'dx;
            end
        end
        else
        begin
            state <= state;
            counter <= counter - 2'd1;
            `ifdef MODEL_TECH
                if (counter == 2'd0)
                    $display("%h", data);
            `endif
        end
    end
end
    
endmodule
