module alternate_sw( input wire CK, input wire i_sw, output reg o_sw );

initial o_sw = 1'b1;

localparam maxcount = 600000;
reg [24:0] counter = 0;
reg prev_i_sw = 0;
always@(posedge CK) begin
    if( counter == 0 ) begin
        if( !prev_i_sw && i_sw ) begin 
            o_sw <= ~o_sw;
            counter += 1;
        end
    end else if( counter == maxcount ) begin
        counter <= 0;
    end else begin
        counter += 1;
    end
    prev_i_sw <= i_sw;
end

endmodule

