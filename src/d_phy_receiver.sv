// D-PHY (CIL-SFNN) receiver that can only do HS RX.
// Why? Some FPGAs have MIPI lines connected to a single port.
// This means you can only pick one IO standard: HSTL 1.2V for LP RX or LVDS for HS RX.
// LVDS is picked, and though this doesn't technically comply with D-PHY, it should work.
// This means the protocol layer should send a reset after receiving the last byte.
// https://www.intel.com/content/www/us/en/programmable/documentation/mcn1446711751001.html#mcn1448380606073
module d_phy_receiver (
    input logic clock_p,
    input logic clock_n,
    input logic data_p,
    input logic data_n,
    // Synchronous reset
    // D-PHY clocks for TCLK-POST after the HS RX ends so this will stick
    input logic reset,
    // Output byte
    output logic [7:0] data,
    // Whether the output byte is valid
    output logic enable
);

// 0 = LP RX or some other non-receiving unknown
// 1 = Synchronized and receiving
logic state = 1'b0;

// Byte counter
logic [3:0] counter = 4'd0;

assign enable = state && counter == 4'd0;

always @(posedge clock_p or posedge clock_n)
begin
    if (reset)
    begin
        data = 8'd0;
        state = 1'b0;
        counter = 4'd0;
    end
    else if (clock_p ^ clock_n) // LP stop could show up as a double posedge
    begin
        data = {data_p, data[7:1]}; // "Each byte shall be transmitted least significant bit first."
        if (!state)
        begin
            if (data == 8'b00011101) // Same-clock acquire sync
            begin
                state = 1'b1;
                counter = 4'd8;
            end
            else // Avoid latch inferrence
            begin
                state = 1'b0;
                counter = 4'd0;
            end
        end
        else
        begin
            state = 1'b1;
            counter = counter == 4'd0 ? 4'd7 : counter - 4'd1;
            `ifdef MODEL_TECH
                if (counter == 4'd0)
                    $display("%h", data);
            `endif
        end
    end
end
    
endmodule
