
module cic_pdm_mic_90M_3M_6k_tb;
    reg ck = 0;
    wire mic_clk;
    reg mic_data = 0;
    wire [17:0] o_data0;
    wire o_vld = 0;
    cic_pdm_mic_90M_3M_6k cic( .CLK(ck), .mic_clk(mic_clk), .mic_data(mic_data), .o_data0(o_data0), .o_vld(o_vld) );
    always #4 ck = ~ck;
    always @(posedge mic_clk) mic_data = ~mic_data;
    reg [19:0] count = 0;
    always @(posedge mic_clk) begin
        count <= count+1;
        if ( 10000 < count ) $finish;
    end
    initial begin
        $dumpfile("cic_pdm_mic_90M_3M_6k_tb.vcd");
        $dumpvars(-1, mic_clk, mic_data, o_vld, o_data0 );
    end
endmodule
