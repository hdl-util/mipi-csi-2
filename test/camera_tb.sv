module camera_tb();

// Initially, lines are grounded
logic clock_p = 0;
logic clock_n = 0;
always
begin
    #2ns;
    clock_n <= ~clock_n;
    clock_p <= clock_n;
end

logic [1:0] data_p = 2'd0;
logic [1:0] data_n;
assign data_n = ~data_p;

logic [1:0] virtual_channel;
logic [15:0] word_count;
logic [7:0] image_data [3:0];
logic [5:0] image_data_type;
logic image_data_enable, interrupt;

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
    .image_data_enable(image_data_enable),
    .interrupt(interrupt)
);

logic [7:0] shift_out [1:0] = '{ 8'd0, 8'd0 };
logic [2:0] shift_index = 3'd0;
always_ff @(posedge clock_p or posedge clock_n)
begin
    data_p[0] <= shift_out[0][shift_index];
    data_p[1] <= shift_out[1][shift_index];
    shift_index <= shift_index + 1'd1;
end

// Short Packet (Virtual Channel: 0, Data Type: 0x08 (Generic Short Packet), Word Count: 0xFACE, ECC: 0x12)
logic [7:0] TEST1 [0:5] = '{8'b10111000, 8'b10111000, 8'h08, 8'hCE, 8'hFA, 8'h12};
// Long Packet (Virtual Channel: 0, Data Type: 0x18 (YUV Data), Word Count: 8, ECC: 0xFE, Data: 0x0D15EA5EFEE1DEAD CRC: 0xF00D)
logic [7:0] TEST2 [0:15] = '{8'b10111000, 8'b10111000, 8'h18, 8'd8, 8'd0, 8'hFE, 8'hAD, 8'hDE, 8'hE1, 8'hFE, 8'h5E, 8'hEA, 8'h15, 8'h0D, 8'hD0, 8'hF0};

integer current_test = 0;
logic [7:0] test_index = 1'd0;
integer image_data_index = 0;
logic [31:0] expected_image_data;
assign expected_image_data = {TEST2[image_data_index + 9], TEST2[image_data_index + 8], TEST2[image_data_index + 7], TEST2[image_data_index + 6]};
logic [31:0] actual_image_data;
assign actual_image_data = {image_data[3], image_data[2], image_data[1], image_data[0]};

always_ff @(posedge clock_p)
begin
    case(current_test)
        0: begin
            if (interrupt)
            begin
                assert (virtual_channel == 2'd0) else $fatal(1, "Virtual channel should be 0");
                assert (camera.header_ecc == TEST1[5]) else $fatal(1, "Header ecc incorrect");
                assert (word_count == {TEST1[4], TEST1[3]}) else $fatal(1, "Expected word count '%h%h' but was %h", TEST1[4], TEST1[3], word_count);
                assert (image_data_type == TEST1[2]) else $fatal(1, "Expected data type %h but was %h", TEST1[2], image_data_type);
                $display("Test 1 complete");
                current_test <= 1;
                test_index <= 1'd0;
            end

            if (test_index < 8'd6 && shift_index == 3'd7)
            begin
                shift_out <= '{TEST1[test_index + 1'd1], TEST1[test_index]};
                test_index <= test_index + 2'd2;
            end
            else if (shift_index == 3'd7) // Allows time for d_phy receiver to see LP00
                shift_out <= '{8'd0, 8'd0};
        end
        1: begin
            if (interrupt)
            begin
                assert (virtual_channel == 2'd0) else $fatal(1, "Virtual channel should be 0");
                assert (camera.header_ecc == TEST2[5]) else $fatal(1, "Header ecc incorrect");
                assert (word_count == {TEST2[4], TEST2[3]}) else $fatal(1, "Expected word count '%h%h' but was %h", TEST2[4], TEST2[3], word_count);
                assert (image_data_type == TEST2[2]) else $fatal(1, "Expected data type %h but was %h", TEST2[2], image_data_type);
                if (image_data_enable)
                begin
                    assert (actual_image_data == expected_image_data) else $fatal(1, "Expected image data to be %h but was %h", expected_image_data, actual_image_data);
                    image_data_index <= image_data_index + 4;
                end
                else
                begin
                    $display("Test 2 complete");
                    $finish;
                end
            end

            if (test_index < 8'd16 && shift_index == 3'd7)
            begin
                shift_out <= '{TEST2[test_index + 1'd1], TEST2[test_index]};
                test_index <= test_index + 2'd2;
            end
        end
    endcase
end

endmodule
