
module nco_4ch(
    input CK,
    input START,
    input [8:0] v_pos,
    input mode_4800,
    output wire signed [17:0] cos0, sin0, cos1, sin1, cos2, sin2, cos3, sin3
);
    reg [2:0] counter = 0;
    // wire ce = ~counter[2];
    wire [10:0] addr = {v_pos, counter[1:0]};
    wire [35:0] dataout_2400, dataout_4800;
    wire signed [17:0] sinout = mode_4800 ? dataout_4800[35:18] : dataout_2400[35:18];
    wire signed [17:0] cosout = mode_4800 ? dataout_4800[17: 0] : dataout_2400[17: 0];
    // nco_rom_4ch_fc4800_fs11718 rom_4ch( .clock(CK), .addr(addr), .dataout(dataout));
    nco_rom_4ch_fc2400_fs11718 rom_4ch_2400( .clock(CK), .addr(addr), .dataout(dataout_2400));
    nco_rom_4ch_fc4800_fs11718 rom_4ch_4800( .clock(CK), .addr(addr), .dataout(dataout_4800));
    // nco_rom_4ch_log4943_fs11718 rom_4ch_4800( .clock(CK), .addr(addr), .dataout(dataout_4800));
    reg signed [17:0] cosrun=0,  sinrun=0;
    always @ (posedge CK) begin
        if( START ) begin
            counter <= 3'd0;
        end else if (counter != 6) begin
            counter <= counter+3'd1;
        end
    end
    reg signed [34:0] cos0w, sin0w, cos1w, sin1w, cos2w, sin2w, cos3w, sin3w;
    assign cos0=cos0w>>>17, sin0=sin0w>>>17, cos1=cos1w>>>17, sin1=sin1w>>>17;
    assign cos2=cos2w>>>17, sin2=sin2w>>>17, cos3=cos3w>>>17, sin3=sin3w>>>17;
    always@(posedge CK) begin
        if ( counter == 0 ) begin
        end else if (counter == 1) begin
            cos0w[34:17] <=18'h1ffff; sin0w[34:17] <= 18'h00000; // nearly one, zero
            cos1w[34:17] <= cosout;   sin1w[34:17] <= sinout; // rom[adr0]
        end else if (counter == 2) begin
            cos2w[34:17] <= cosout;   sin2w[34:17] <= sinout; // rom[hi,lo=1]
        end else if (counter == 3) begin
            cos3w[34:17] <= cosout;   sin3w[34:17] <= sinout; // rom[lo=2]
        end else if (counter == 4) begin
            cosrun <= cosout;         sinrun <= sinout; //rom[hi+lo=3]
        end else begin
            cos0w <= (cos0*cosrun - sin0*sinrun); sin0w <= (sin0*cosrun + cos0*sinrun);
            cos1w <= (cos1*cosrun - sin1*sinrun); sin1w <= (sin1*cosrun + cos1*sinrun);
            cos2w <= (cos2*cosrun - sin2*sinrun); sin2w <= (sin2*cosrun + cos2*sinrun);
            cos3w <= (cos3*cosrun - sin3*sinrun); sin3w <= (sin3*cosrun + cos3*sinrun);
        end
    end
endmodule
