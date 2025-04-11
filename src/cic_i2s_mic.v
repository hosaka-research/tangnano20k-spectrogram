`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/02/09 21:30:34
// Design Name: 
// Module Name: cic_i2s_mic_3M_12k
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// I2S mic driven by 3MHz
// Fs is NOT 6k, but 5859.375Hz = 3MHz/512
//////////////////////////////////////////////////////////////////////////////////

module cic_i2s_mic_90M_3M_6k( input wire clk, output wire o_mic_clk, output wire o_mic_ws, input wire i_mic_data,
                                output wire[17:0] o_data0, output wire[17:0] o_data1, output wire o_vld, input RST );
    reg pulse_flag = 0;
    reg signed [23:0] mic_shift=0;
    reg signed [33:0] data0I1=34'd0, data0D0=34'd0, data0B1=34'd0;
    reg signed [33:0] data0I2=34'd0, data0D1=34'd0, data0B2=34'd0;
    reg signed [33:0] data0I3=34'd0, data0D2=34'd0, data0B3=34'd0;
    reg [5:0] mic_count=0;
    reg mic_clk = 0;
    reg [5:0] bit_count=0;
    reg mic_ws = 0;
    reg [2:0] data_count=0;
    reg vld = 0;
    assign o_mic_clk = mic_clk;
    assign o_mic_ws = mic_ws;
    assign o_data1 = (18'b0);
    // generate mic clock and other timing
    always@(posedge clk) begin // clock signal generation
        if( mic_count != 6'd14 ) begin // (90MHz/6MHz-1) each cycle) 
            mic_count <= mic_count+1;
            vld <= 0; // TAKE CARE
        end else begin
            mic_count <= 0;
            mic_clk <= !mic_clk; // flip 6MHz -> 3MHz, mic clock is 3MHz
            if( mic_clk == 1 ) begin
                if( bit_count != 6'd31 ) begin
                    bit_count <= bit_count+1;
                end else begin
                    bit_count <= 0;
                    mic_ws <= !mic_ws; // 3MHz/32 = 46875Hz, 0 if Left, 1 if Right
                    if ( mic_ws == 1 ) begin
                        if( data_count != 3'h7 ) begin //  46875Hz/5859.375Hz-1
                            data_count <= data_count+1;
                        end else begin
                            data_count <= 0;
                            vld <= 1; // TAKE CARE
                        end
                    end
                end
            end
        end
    end
    // Downsample to 5859.375Hz by CIC filter
    always@(posedge clk) begin
        if ( mic_count == 6'd14 && mic_clk == 1'd1 ) begin // Data sampled when mic_clk 0->1
            if ( mic_ws == 0 ) begin
                if( 7'd1 == bit_count ) begin
                    mic_shift <= 0;
                end else if( 7'd2 <= bit_count && bit_count < 7'd26 ) begin
                    mic_shift <= (mic_shift << 1) | i_mic_data;
                end else if ( bit_count == 7'd26 ) begin
                    data0I1 <= data0I1 + mic_shift;
                    data0I2 <= data0I2 + data0I1;
                    data0I3 <= data0I3 + data0I2;
                end else if ( bit_count == 7'd27 && data_count == 3'd7 ) begin
                    data0B3 <= data0I3; data0D2 <= data0I3 - data0B3;
                    data0B2 <= data0D2; data0D1 <= data0D2 - data0B2;
                    data0B1 <= data0D1; data0D0 <= data0D1 - data0B1;
                end
            end
        end
    end
    // Low cut filter and Automatic Gain Control
    wire signed [31:0] o_low_cut;
    wire o_low_cut_vld;
    low_cut lc( .CLK(clk), .i_vld( vld ), .i_data( data0D0>>>8 ), .o_vld( o_low_cut_vld ), .o_data( o_low_cut ));
    wire o_agc_valid;
    wire [17:0] o_agc_data;
    simple_AGC agc( .CLK(clk), .i_vld(o_low_cut_vld), .i_data(o_low_cut), .o_vld(o_agc_vld), .o_data(o_agc_data), 
        .o_range_over(o_range_over), .RST(RST) );
    assign o_data0 = $signed(o_agc_data); // NEEDS AGC LATER
    assign o_vld = o_agc_vld;
endmodule

module cic_i2s_mic_120M_3M_6k( input wire clk, output wire o_mic_clk, output wire o_mic_ws, input wire i_mic_data,
                                output wire[17:0] o_data0, output wire[17:0] o_data1, output wire o_vld, input RST );
    reg pulse_flag = 0;
    reg signed [23:0] mic_shift=0;
    reg signed [33:0] data0I1=34'd0, data0D0=34'd0, data0B1=34'd0;
    reg signed [33:0] data0I2=34'd0, data0D1=34'd0, data0B2=34'd0;
    reg signed [33:0] data0I3=34'd0, data0D2=34'd0, data0B3=34'd0;
    reg [5:0] mic_count=0;
    reg mic_clk = 0;
    reg [5:0] bit_count=0;
    reg mic_ws = 0;
    reg [2:0] data_count=0;
    reg vld = 0;
    assign o_mic_clk = mic_clk;
    assign o_mic_ws = mic_ws;
    assign o_data1 = (18'b0);
    // generate mic clock and other timing
    always@(posedge clk) begin
        if( mic_count != 6'd19 ) begin // (120MHz/6MHz-1) each cycle) 
            mic_count <= mic_count+1;
            vld <= 0; // TAKE CARE
        end else begin
            mic_count <= 0;
            mic_clk <= !mic_clk; // flip 6MHz -> 3MHz, mic clock is 3MHz
            if( mic_clk == 1 ) begin
                if( bit_count != 6'd31 ) begin
                    bit_count <= bit_count+1;
                end else begin
                    bit_count <= 0;
                    mic_ws <= !mic_ws; // 3MHz/32 = 46875Hz, 0 if Left, 1 if Right
                    if ( mic_ws == 1 ) begin
                        if( data_count != 3'h7 ) begin //  46875Hz/5859.375Hz-1
                            data_count <= data_count+1;
                        end else begin
                            data_count <= 0;
                            vld <= 1; // TAKE CARE
                        end
                    end
                end
            end
        end
    end
    // Downsample to 5859.375Hz by CIC filter
    always@(posedge clk) begin 
        if ( mic_count == 6'd19 && mic_clk == 1'd1 ) begin // Data sampled when mic_clk 0->1
            if ( mic_ws == 0 ) begin
                if( 7'd1 == bit_count ) begin
                    mic_shift <= 0;
                end else if( 7'd2 <= bit_count && bit_count < 7'd26 ) begin
                    mic_shift <= (mic_shift << 1) | i_mic_data;
                end else if ( bit_count == 7'd26 ) begin
                    data0I1 <= data0I1 + mic_shift;
                    data0I2 <= data0I2 + data0I1;
                    data0I3 <= data0I3 + data0I2;
                end else if ( bit_count == 7'd27 && data_count == 3'd7 ) begin
                    data0B3 <= data0I3; data0D2 <= data0I3 - data0B3;
                    data0B2 <= data0D2; data0D1 <= data0D2 - data0B2;
                    data0B1 <= data0D1; data0D0 <= data0D1 - data0B1;
                end
            end
        end
    end
    // Apply Low cut filter
    wire signed [31:0] o_low_cut;
    wire o_low_cut_vld;
    low_cut lc( .CLK(clk), .i_vld( vld ), .i_data( data0D0>>>8 ), .o_vld( o_low_cut_vld ), .o_data( o_low_cut ));
    // apply Automatic Gain Control
    wire o_agc_valid;
    wire [17:0] o_agc_data;
    simple_AGC agc( .CLK(clk), .i_vld(o_low_cut_vld), .i_data(o_low_cut), .o_vld(o_agc_vld), .o_data(o_agc_data), 
        .o_range_over(o_range_over), .RST(RST) );
    assign o_data0 = $signed(o_agc_data);
    assign o_vld = o_agc_vld;
endmodule

/*  I2C Mic input frontend
    main clock freq = 120MHz
    PDM microphone clock freq = 3MHz (NOT 3.072 MHz)
    output audio data fs = 11718.75Hz( 3MHz/256 )
*/
module cic_i2s_mic_120M_3M_11718( input wire clk, output wire o_mic_clk, output wire o_mic_ws, input wire i_mic_data,
                                output wire[17:0] o_data0, output wire[17:0] o_data1, output wire o_vld, input RST );
    reg pulse_flag = 0;
    reg signed [23:0] mic_shift=0;
    reg signed [33:0] data0I1=34'd0, data0D0=34'd0, data0B1=34'd0;
    reg signed [33:0] data0I2=34'd0, data0D1=34'd0, data0B2=34'd0;
    reg signed [33:0] data0I3=34'd0, data0D2=34'd0, data0B3=34'd0;
    reg [5:0] mic_count=0;
    reg mic_clk = 0;
    reg [5:0] bit_count=0;
    reg mic_ws = 0;
    reg [2:0] data_count=0;
    reg vld = 0;
    assign o_mic_clk = mic_clk;
    assign o_mic_ws = mic_ws;
    assign o_data1 = (18'b0);
    // generate mic clock and other timing
    always@(posedge clk) begin // clock signal generation
        if( mic_count != 6'd19 ) begin // (120MHz/6MHz-1) each cycle) 
            mic_count <= mic_count+1;
            vld <= 0; // TAKE CARE
        end else begin
            mic_count <= 0;
            mic_clk <= !mic_clk; // flip 6MHz -> 3MHz, mic clock is 3MHz
            if( mic_clk == 1 ) begin
                if( bit_count != 6'd31 ) begin
                    bit_count <= bit_count+1;
                end else begin
                    bit_count <= 0;
                    mic_ws <= !mic_ws; // 3MHz/64 = 46875Hz, 0 if Left, 1 if Right
                    if ( mic_ws == 1 ) begin
                        if( data_count != 3'h3 ) begin //  46875Hz/(11718.75Hz)-1
                            data_count <= data_count+1;
                        end else begin
                            data_count <= 0;
                            vld <= 1; // TAKE CARE
                        end
                    end
                end
            end
        end
    end
    // Downsample from 46875Hz to 11718.75Hz by CIC filter
    always@(posedge clk) begin 
        if ( mic_count == 6'd19 && mic_clk == 1'd1 ) begin // Data sampled when mic_clk 0->1 (120MHz/6MHz-1)
            if ( mic_ws == 0 ) begin
                if( 7'd1 == bit_count ) begin
                    mic_shift <= 0;
                end else if( 7'd2 <= bit_count && bit_count < 7'd26 ) begin
                    mic_shift <= (mic_shift << 1) | i_mic_data;
                end else if ( bit_count == 7'd26 ) begin
                    data0I1 <= data0I1 + mic_shift;
                    data0I2 <= data0I2 + data0I1;
                    data0I3 <= data0I3 + data0I2;
                end else if ( bit_count == 7'd27 && data_count == 3'd3 ) begin
                    data0B3 <= data0I3; data0D2 <= data0I3 - data0B3;
                    data0B2 <= data0D2; data0D1 <= data0D2 - data0B2;
                    data0B1 <= data0D1; data0D0 <= data0D1 - data0B1;
                end
            end
        end
    end
    // Apply Low cut filter
    wire signed [31:0] o_low_cut;
    wire o_low_cut_vld;
    low_cut lc( .CLK(clk), .i_vld( vld ), .i_data( data0D0>>>8 ), .o_vld( o_low_cut_vld ), .o_data( o_low_cut ));
    // Apply Automatic Gain Control
    wire o_agc_valid;
    wire [17:0] o_agc_data;
    simple_AGC agc( .CLK(clk), .i_vld(o_low_cut_vld), .i_data(o_low_cut), .o_vld(o_agc_vld), .o_data(o_agc_data), 
        .o_range_over(o_range_over), .RST(RST) );
    assign o_data0 = $signed(o_agc_data);
    assign o_vld = o_agc_vld;
endmodule


