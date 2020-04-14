module camera_tb();

// Initially, lines are grounded
logic clock_p = 0;
logic clock_n = 0;
always
begin
    #2ns;
    clock_p <= ~clock_p;
    clock_n <= clock_p;
end

logic [1:0] data_p = 2'd0;
logic [1:0] data_n;
assign data_n = ~data_p;

logic [1:0] virtual_channel;
logic [15:0] word_count;
logic [7:0] image_data [3:0];
logic [5:0] image_data_type;
logic image_data_enable;

camera #(.NUM_LANES(2)) camera (
    .clock_p(clock_p),
    .data_p(data_p),
    // Corresponding virtual channel for the image data
    .virtual_channel(virtual_channel),
    // Total number of words in the current packet
    .word_count(word_count),
    // See Section 12 for how this should be parsed
    .image_data(image_data),
    .image_data_type(image_data_type),
    // Whether there is output data ready
    .image_data_enable(image_data_enable)
);

logic [7:0] shift_out [1:0] = '{ 8'd0, 8'd0 };
logic [2:0] shift_index = 3'd0;
always @(posedge clock_p or posedge clock_n)
begin
    data_p[0] <= shift_out[0][shift_index];
    data_p[1] <= shift_out[1][shift_index];
    shift_index <= shift_index + 1'd1;
end

// Short Packet (Virtual Channel: 0, Data Type: 0x08 (Generic Short Packet), Word Count: 0xFACE, ECC: 0x12)
logic [7:0] TEST1 [0:3] = '{8'h08, 8'hCE, 8'hFA, 8'h12};
// Long Packet (Virtual Channel: 0, Data Type: 0x18 (YUV Data), Word Count: 8, ECC: 0xFE, Data: 0x0D15EA5EFEE1DEAD CRC: 0xF00D)
logic [7:0] TEST2 [0:13] = '{8'h18, 8'd8, 8'd0, 8'hFE, 8'hAD, 8'hDE, 8'hE1, 8'hFE, 8'h5E, 8'hEA, 8'h15, 8'h0D, 8'hD0, 8'hF0};

integer i;
initial
begin
    // Shift out sync
    wait (shift_index != 8'd0); wait (shift_index == 8'd0);
    shift_out[0] <= 8'b00011101;
    shift_out[1] <= 8'b00011101;

    // Shift out bytes
    for (i = 0; i < 4; i+= 2)
    begin
        wait (shift_index != 8'd0); wait (shift_index == 8'd0);
        shift_out[0] <= TEST1[i];
        shift_out[1] <= TEST1[i+1];
    end

    wait (camera.reset[0] == 1'd1);
    assert (word_count == {TEST1[2], TEST1[1]}) else $fatal(1, "Expected word count '%h%h' but was %h", TEST1[2], TEST1[1], word_count);
    assert (image_data_type == TEST1[0]) else $fatal(1, "Expected data type %h but was %h", TEST1[0], image_data_type);

    wait (camera.reset[0] == 1'd0);


    // Shift out sync
    wait (shift_index != 8'd0); wait (shift_index == 8'd0);
    shift_out[0] <= 8'b00011101;
    shift_out[1] <= 8'b00011101;

    // Shift out bytes
    for (i = 0; i < 14; i+= 2)
    begin
        wait (shift_index != 8'd0); wait (shift_index == 8'd0);
        shift_out[0] <= TEST2[i];
        shift_out[1] <= TEST2[i+1];
        if (i % 4 == 2 && i > 6) // Skip header, straight to data checking
        begin
            assert (image_data_enable) else $fatal(1, "Image data not enabled on receiving the fourth byte");
            assert (image_data == '{TEST2[i-3], TEST2[i-4], TEST2[i-5], TEST2[i-6]}) else $fatal(1, "Expected buffer to be %h but was %h", {TEST2[i-3], TEST2[i-4], TEST2[i-5], TEST2[i-6]}, {image_data[3], image_data[2], image_data[1], image_data[0]});
        end
        else
        begin
            assert (!image_data_enable);
        end
    end

    wait (camera.reset[0] == 1'd1);
    assert (word_count == {TEST2[2], TEST2[1]}) else $fatal(1, "Expected word count '%h%h' but was %h", TEST2[2], TEST2[1], word_count);
    assert (image_data_type == TEST2[0]) else $fatal(1, "Expected data type %h but was %h", TEST2[0], image_data_type);
    $finish;
end

endmodule
