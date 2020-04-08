module camera_tb();
initial
begin
    $finish;
end

// Initially, lines are grounded
logic clock_p = 0;
logic clock_n = 0;
always
begin
    #2ns;
    clock_p <= ~clock_p;
    clock_n <= clock_p;
end

logic [1:0] virtual_channel;
logic [15:0] word_count;
logic [31:0] image_data;
logic [7:0] image_data_type;
logic image_data_enable;

camera #(.NUM_LANES(2)) camera (
    .clock_p(clock_p),
    .clock_n(clock_n),
    .data_p(),
    .data_n(),
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

endmodule
