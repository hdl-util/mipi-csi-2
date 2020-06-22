module d_phy_receiver_tb();

// Initially, lines are grounded
logic clock_p = 0;
logic clock_n = 0;
always
begin
    #2ns;
    clock_n <= ~clock_n;
    clock_p <= clock_n;
end

logic data_p = 0;
logic data_n;
assign data_n = ~data_p;

logic reset = 0;
logic [7:0] data;
logic enable;

d_phy_receiver d_phy_receiver (
    .clock_p(clock_p),
    .data_p(data_p),
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

localparam TEST1_LEN = 128;
logic [7:0] TEST1 [0:TEST1_LEN-1] = '{8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF, 8'hFE, 8'hED, 8'hFA, 8'hCE, 8'hCA, 8'hFE, 8'hBE, 8'hEF};

integer i = -2;
always @(posedge clock_p)
begin
    if (shift_index == 3'd7 && i < TEST1_LEN)
    begin
        if (i == -2)
            shift_out <= 8'd0;
        else if (i == -1)
            shift_out <= 8'b10111000;
        else
            shift_out <= TEST1[i];
        i <= i + 1;
    end
    if (enable && i > 0 && i <= TEST1_LEN + 1)
    begin
        assert(data == TEST1[i - 2]) else $fatal(1, "data not expected: %h vs %h", data, TEST1[i - 2]);
        if (i >= TEST1_LEN)
            i <= i + 1;
    end
    else if (i > TEST1_LEN + 1)
    begin
        assert(!enable) else $fatal(1, "unexpected enables after TX finished");
        if (i == TEST1_LEN + 2)
            reset <= 1'd1;
        else if (i == TEST1_LEN + 3)
            reset <= 1'd0;
        else
        begin
            assert(d_phy_receiver.state == 2'd0) else $fatal(1, "receiver is in %d but should've returned to UNKNOWN", d_phy_receiver.state);
            $finish;
        end
        i <= i + 1;
    end
    

end

endmodule
