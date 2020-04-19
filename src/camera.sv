module camera #(
    parameter NUM_LANES = 2
) (
    input logic clock_p,
    input logic [NUM_LANES-1:0] data_p,
    // Corresponding virtual channel for the image data
    output logic [1:0] virtual_channel,
    // Total number of words in the current packet
    output logic [15:0] word_count,

    output logic interrupt,

    // See Section 12 for how this should be parsed
    output logic [7:0] image_data [0:3] = '{8'd0, 8'd0, 8'd0, 8'd0},
    output logic [5:0] image_data_type,
    // Whether there is output data ready
    output logic image_data_enable,

    output logic frame_start,
    output logic frame_end,
    output logic line_start,
    output logic line_end,

    // The  intention  of  the  Generic  Short  Packet  Data  Types  is  to  provide  a  mechanism  for  including  timing 
    // information for the opening/closing of shutters, triggering of flashes, etc within the data stream.
    output logic generic_short_data_enable,
    output logic [15:0] generic_short_data
);

assign interrupt = image_data_enable || reset[0];

logic [NUM_LANES-1:0] reset = NUM_LANES'(0);
logic [7:0] data [NUM_LANES-1:0];
logic [NUM_LANES-1:0] enable;

genvar i;
generate
    for (i = 0; i < NUM_LANES; i++)
    begin: lane_receivers
        d_phy_receiver d_phy_receiver (
            .clock_p(clock_p),
            .data_p(data_p[i]),
            .reset(reset[i]),
            .data(data[i]),
            .enable(enable[i])
        );
    end
endgenerate

logic [7:0] packet_header [3:0] = '{8'd0, 8'd0, 8'd0, 8'd0};
assign virtual_channel = packet_header[0][7:6];
logic [5:0] data_type;
assign data_type = packet_header[0][5:0];
assign image_data_type = data_type;

assign frame_start = data_type == 6'd0;
assign frame_end = data_type == 6'd1;
assign line_start = data_type == 6'd2;
assign line_end = data_type == 6'd3;
assign generic_short_data_enable = data_type >= 6'd8 && data_type <= 6'hF && reset[0];
assign generic_short_data = word_count;

assign word_count = {packet_header[2], packet_header[1]}; // Recall: LSB first
logic [7:0] header_ecc;
assign header_ecc = packet_header[3];

logic [2:0] header_index = 3'd0;
logic [16:0] word_counter = 17'd0;
logic [1:0] data_index = 2'd0;

// Count off multiples of four
// Shouldn't be the first byte
assign image_data_enable = data_type >= 6'h18 && data_type <= 6'h2F && word_counter != 17'd0 && (data_index == 2'd0 || word_counter == word_count);

integer j;
always @(posedge clock_p)
begin
    // Lane reception
    for (j = 0; j < NUM_LANES; j++)
    begin
        if (enable[j]) // Receive byte
        begin
            if (header_index < 3'd4) // Packet header
            begin
                packet_header[header_index] <= data[j];
                header_index = header_index + 1'd1;
            end
            else // Long packet receive
            begin
                // Image data (YUV, RGB, RAW)
                if (data_type >= 6'h18 && data_type <= 6'h2F && word_counter < word_count)
                begin
                    image_data[data_index] <= data[j];
                    data_index = data_index + 2'd1; // Wrap-around 4 byte counter
                end
                // Footer
                else
                begin
                end
                word_counter = word_counter + 17'd1;
            end
        end
    end

    // Lane resetting
    for (j = 0; j < NUM_LANES; j++)
    begin
        if (enable != NUM_LANES'(0))
        begin
            if (data_type <= 6'h0F && header_index + 3'(j) >= 3'd4 && !reset[j]) // Reset on short packet end
            begin
                `ifdef MODEL_TECH
                    $display("Resetting lane %d", 3'(j + 1));
                `endif
                reset[j] <= 1'b1;
            end
            else if (header_index + 3'(j) >= 3'd4 && header_index + word_counter + 17'(j) >= 17'(word_count) + 17'd2 + 3'd4 && !reset[j]) // Reset on long packet end
            begin
                `ifdef MODEL_TECH
                    $display("Resetting lane %d", 3'(j + 1));
                `endif
                reset[j] <= 1'b1;
            end
        end
    end
    // Synchronous state reset (next clock)
    if (reset[0]) // Know the entire state is gone for sure if the first lane resets
    begin
        packet_header <= '{8'd0, 8'd0, 8'd0, 8'd0};
        image_data <= '{8'd0, 8'd0, 8'd0, 8'd0};
        header_index = 3'd0;
        word_counter = 17'd0;
        data_index = 2'd0;
        reset <= NUM_LANES'(0);
    end
end

endmodule
