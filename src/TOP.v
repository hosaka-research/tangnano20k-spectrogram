
module TOP
(
	input			Reset_Button,
    input           User_Button,
    input           XTAL_IN,
	output			LCD_CLK,
	output			LCD_HSYNC,
	output			LCD_VSYNC,
	output			LCD_DENBL,
	output	[4:0]	LCD_R,
	output	[5:0]	LCD_G,
	output	[4:0]	LCD_B,
    input  wire MIC_SDATA0,
    output wire MIC_CK0,
    output wire MIC_WS0,
    output wire MIC_LR0
);
    assign SDATA_OUT = MIC_SDATA0; // avoid compiler warning
    assign MIC_CK0 = MIC_CLK;
    assign MIC_LR0 = 1'b0; // zero if left

    wire CLK;
    wire pll_lock;
    Gowin_rPLL_27M_120M chip_pll ( .clkout(CLK), .clkin(XTAL_IN), .lock(pll_lock) );

    wire [17:0] AUDIO;
    wire        AUDIORDY;
    wire        oscout_o;
    wire MIC_CLK;
    cic_i2s_mic_120M_3M_11718 mic( .clk(CLK), .o_mic_clk(MIC_CLK), .o_mic_ws(MIC_WS0), .i_mic_data(MIC_SDATA0),
                                .o_data0(AUDIO), .o_vld(AUDIORDY), .RST(!pll_lock)  );

    wire sw1_alt;
    alternate_sw a_sw1( .CK(MIC_CLK), .i_sw(Reset_Button), .o_sw(sw1_alt) );
    wire sw2_alt;
    alternate_sw a_sw2( .CK(MIC_CLK), .i_sw(User_Button),  .o_sw(sw2_alt) );

    wire [15:0] LCD_RGB565;
    assign { LCD_R, LCD_G, LCD_B } = LCD_RGB565;
    VGAMod2	D1(
		.CLK(CLK),
		.nRST( 1'd0 ),
		.PixelClk ( LCD_CLK ),
		.LCD_DE( LCD_DENBL ),
		.LCD_HSYNC( LCD_HSYNC ),
        .LCD_VSYNC( LCD_VSYNC ),
        .LCD_RGB565( LCD_RGB565 ),
        .AUDIO(AUDIO), .AUDIORDY(AUDIORDY),
        .AUDIORUN(sw1_alt), .mode_4800(!sw2_alt)
	);
endmodule

