module rgb565 (
    input logic [7:0] image_data [3:0],
    input logic image_data_enable,
    output logic [15:0] rgb [1:0],
    output logic rgb_enable
);

logic [31:0] unpacked_image_data;
assign unpacked_image_data = {image_data[3], image_data[2], image_data[1], image_data[0]};

assign rgb[0] = {unpacked_image_data[15:11], unpacked_image_data[10:5], unpacked_image_data[4:0]};
assign rgb[1] = {unpacked_image_data[31:27], unpacked_image_data[26:21], unpacked_image_data[20:16]};
assign rgb_enable = image_data_enable;

endmodule
