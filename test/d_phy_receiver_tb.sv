module d_phy_receiver_tb();

// Initially, lines are grounded
logic clock_p = 0;
logic clock_n = 0;
always
begin
    #2ns;
    clock_p <= ~clock_p;
    clock_n <= clock_p;
end

logic data_p = 0;
logic data_n;
assign data_n = ~data_p;

logic reset = 0;
logic [7:0] data;
logic enable;

d_phy_receiver d_phy_receiver (
    .clock_p(clock_p),
    .clock_n(clock_n),
    .data_p(data_p),
    .data_n(data_n),
    // Synchronous reset
    // D-PHY clocks for TCLK-POST after the HS RX ends so this will stick
    .reset(reset),
    // Output byte
    .data(data),
    // Whether the output byte is valid
    .enable(enable)
);

logic [7:0] shift_out = 8'd0;
logic [2:0] shift_index = 3'd0;
always @(posedge clock_p or posedge clock_n)
begin
    data_p <= shift_out[shift_index]; // Recall: LSB first
    shift_index <= shift_index + 1'd1;
end

logic [7:0] TEST1 [7:0] = '{8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF};
integer i;

initial
begin
    // Shift out sync
    wait (shift_index != 8'd0); wait (shift_index == 8'd0);
    shift_out <= 8'b00011101;

    // Shift out bytes
    for (i = 0; i < 8; i++)
    begin
        wait (shift_index != 8'd0); wait (shift_index == 8'd0);
        shift_out <= TEST1[i];
        if (i != 0)
        begin
            wait (enable);
            assert (data === TEST1[i - 1]) else $fatal(1, "Received data incorrect for %d: expected %h, got %h", 4'(i), TEST1[i-1], data);
        end
    end

    wait (shift_index != 8'd0); wait (shift_index == 8'd0);
    wait (enable);
    assert (data == TEST1[7]) else $fatal(1, "Received data incorrect for %d: expected %h, got %h", 4'(7), TEST1[7], data);
    

    reset <= 1'd1; // Reset should be applied without any spurious enables, even if it is delayed by a few clocks
    wait (shift_index != 8'd0);
    wait (shift_index != 8'd1);
    assert (d_phy_receiver.state == 1'b0);
    $finish;
end

endmodule
