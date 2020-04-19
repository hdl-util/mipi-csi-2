// D-PHY (CIL-SFNN) receiver that can only do HS RX.
// Why? Some FPGAs have MIPI lines connected to a single port.
// This means you can only pick one IO standard: HSTL 1.2V for LP RX or LVDS for HS RX.
// LVDS is picked, and though this doesn't technically comply with D-PHY, it should work.
// This means the protocol layer should send a reset after receiving the last byte.
// https://www.intel.com/content/www/us/en/programmable/documentation/mcn1446711751001.html#mcn1448380606073
module d_phy_receiver (
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

logic dataout_h = 1'd0;
logic dataout_l = 1'd0;

always @(posedge clock_p) dataout_h <= data_p;
always @(negedge clock_p) dataout_l <= data_p;

// 0 = LP RX or some other non-receiving unknown
// 1 = In phase sync
// 2 = Out of phase sync
logic [1:0] state = 2'd0;

logic [8:0] internal_data = 9'd0;
assign data = state == 2'd2 ? internal_data[7:0] : internal_data[8:1];

// Byte counter
logic [1:0] counter = 2'd0;

assign enable = state != 2'd0 && counter == 2'd0;

always @(posedge clock_p)
begin
    if (reset)
    begin
        internal_data <= 8'd0;
        state <= 2'd0;
        counter <= 2'd0;
    end
    else
    begin
        internal_data <= {dataout_l, dataout_h, internal_data[8:2]}; // "Each byte shall be transmitted least significant bit first."
        if (state == 2'd0)
        begin
            if (internal_data[8:1] == 8'b10111000) // In phase sync sync
            begin
                state <= 2'd1;
                counter <= 2'd3;
            end
            else if (internal_data[7:0] == 8'b10111000) // Out of phase sync
            begin
                state <= 2'd2;
                counter <= 2'd3;
            end
            else
            begin
                state <= 2'd0;
                counter <= 2'd3;
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
