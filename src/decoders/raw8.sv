module raw8 (
    input logic [7:0] image_data [3:0],
    input logic image_data_enable,
    output logic [7:0] raw [3:0],
    output logic raw_enable
);
assign raw = image_data;
assign raw_enable = image_data_enable;

endmodule
