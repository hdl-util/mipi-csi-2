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

logic data_p_l;
always @(negedge clock_p) data_p_l <= data_p;

// 0 = LP RX or some other non-receiving unknown
// 1 = In phase sync
// 2 = Out of phase sync
logic [1:0] state = 2'd0;

logic [8:0] internal_data = 9'dX;
assign data = state == 2'd2 ? internal_data[7:0] : internal_data[8:1];

// Byte counter
logic [2:0] counter = 4'd0;

assign enable = state != 2'd0 && counter == 3'd0;

always @(posedge clock_p)
begin
    if (reset)
    begin
        internal_data = 8'd0;
        state <= 2'd0;
        counter <= 4'd0;
    end
    else // if (clock_p ^ clock_n) // LP stop could show up as a double posedge
    begin
        internal_data = {data_p, data_p_l, internal_data[8:2]}; // "Each byte shall be transmitted least significant bit first."
        if (state == 2'd0)
        begin
            if (internal_data == 9'b000111010) // In phase sync sync
            begin
                // $display("ACK");
                state <= 2'd1;
                counter <= 3'd4;
            end
            else if (internal_data == 9'b000011101) // Out of phase sync
            begin
                state <= 2'd2;
                counter <= 3'd4;
            end
            else
            begin
                state <= 2'd0;
                counter <= 3'd0;
            end
        end
        else
        begin
            state <= state;
            counter <= counter == 3'd0 ? 3'd3 : counter - 3'd1;
            `ifdef MODEL_TECH
                if (counter == 4'd0)
                    $display("%h", data);
            `endif
        end
    end
end
    
endmodule
