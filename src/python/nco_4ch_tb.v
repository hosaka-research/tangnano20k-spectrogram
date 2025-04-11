
module main();
    reg CK = 0;
    always #4 CK = ~CK;
    reg [31:0] count = 0;
    wire signed [17:0] cos0, sin0, cos1, sin1, cos2, sin2, cos3, sin3;
    wire start = (count<2); 
    nco_4ch nco( .CK(CK), .START(start), .v_pos(9'd20), .mode_4800(1'b0),
         .cos0(cos0), .sin0(sin0), .cos1(cos1), .sin1(sin1), .cos2(cos2), .sin2(sin2), .cos3(cos3), .sin3(sin3) );
    always@(posedge CK) begin
        count <= count+1;
        if ( 128*4 < count ) $finish;
    end
    initial begin
        $dumpfile( "./nco_4ch_tb.vcd" );
        $dumpvars( -1, CK, start, cos0, sin0, cos1, sin1, cos2, sin2, cos3, sin3, count );
    end
endmodule

