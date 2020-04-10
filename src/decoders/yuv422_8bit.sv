module yuv422_8bit (
    input logic [7:0] image_data [3:0],
    input logic image_data_enable,
    output logic [23:0] yuv [1:0],
    output logic yuv_enable
);
assign yuv[0] = {image_data[2], image_data[3], image_data[1]};
assign yuv[1] = {image_data[0], image_data[3], image_data[1]};
assign yuv_enable = image_data_enable;

endmodule
