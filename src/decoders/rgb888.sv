module rgb888 (
    input logic clock_p,
    input logic clock_n,
    input logic [7:0] image_data [3:0],
    input logic image_data_enable,
    output logic [23:0] rgb [1:0],
    output logic [1:0] rgb_enable
);

//     Fifo    Memory Order
// 0 = BGRB -> BRGB
// 1 = GRBG -> GBRG
// 2 = RBGR -> RGBR
logic [1:0] state = 2'd0;

logic [7:0] last_upper_image_data [1:0] = '{8'd0, 8'd0};

assign rgb_enable[0] = image_data_enable;
assign rgb_enable[1] = image_data_enable && state == 2'd2;

assign rgb[0] = state == 2'd0 ? {image_data[2], image_data[1], image_data[0]}
    : state == 2'd1 ? {image_data[1], image_data[0], last_upper_image_data[3]}
    : state == 2'd2 ? {image_data[0], last_upper_image_data[3], last_upper_image_data[2]};

assign rgb[1] = {image_data[3], image_data[2], image_data[1]};

always @(posedge clock_p or posedge clock_n)
begin
    if (image_data_enable)
    begin
        state <= state == 2'd2 ? 2'd0 : state + 2'd1;
        last_upper_image_data <= image_data[3:2];
    end
end

endmodule
