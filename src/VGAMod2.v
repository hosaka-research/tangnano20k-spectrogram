
module VGAMod2
(
    input CLK,
    input nRST,

    output PixelClk,
    output LCD_DE,
    output LCD_HSYNC,
    output LCD_VSYNC,
    output [15:0] LCD_RGB565, 
    input signed [17:0] AUDIO,
    input AUDIORDY,
    input AUDIORUN,
    input mode_4800
);

/////////////////////////////
// C counter, One hot state machine
/////////////////////////////
localparam c_stop = 4; // 90MHz/22.5MHz, MUST BE EVEN 
reg[c_stop-1:0] c_S = 4'b0;
always@(posedge CLK) c_S <= (c_S[c_stop-2:0]==0)?(4'b1):(c_S<<1); 
wire c_isend = c_S[3]; // Check if counter is at end count  
wire c_stopM3 = c_S[1]; // A pixel changes at 3rd posedge of CLK
// 5,0,1 -> PixelClk goes 1 // 2,3,4->PixelClk goes 0
reg PCLK = 0;
always@(posedge CLK) PCLK <= (c_S[0]|c_S[3]);
assign PixelClk = PCLK;

/////////////////////////////
// H counter
/////////////////////////////
localparam h_blank  =  11'd46;
localparam h_pulse  =   1; 
localparam h_disp   = h_blank + 800;
localparam h_noinp  = h_disp + 128;
localparam h_stop   = h_disp + 210;

reg[10:0] h_count   = 0; // Count pixel clock to generate vertical clock
wire h_isend = (c_isend&&(h_count==h_stop-1));
wire h_isdispend =  (c_isend&&(h_count==h_disp-1));
wire h_isnoinp   =   ((h_disp <= h_count)&&(h_count < h_noinp));
wire h_isnoinpend =  (c_isend&&(h_count==h_noinp-1));
always@(posedge CLK) if(c_isend) h_count <= h_count==h_stop-1'h1 ? 1'h0 : h_count+1'h1;
wire [9:0] h_pos=(h_count-h_blank);
reg h_sync = 1;
always@(posedge CLK) if(c_isend) h_sync <= (((h_pulse-1'h1)<=h_count)&&(h_count<=(h_disp-1'h1)));
assign LCD_HSYNC = h_sync;
wire h_enable = ((h_blank-1<=h_count)&&(h_count <= h_disp-1'h1));
wire h_validdata = ((h_count<=(h_disp-1'h1)));

/////////////////////////////
// V counter
/////////////////////////////
localparam v_blank =   0;
localparam v_pulse =   5; 
localparam v_disp  = 480;
localparam v_stop  = v_disp + 45;

reg[ 9:0] v_count   = 0; // Count vertical clock to generate frame clock
wire v_isend = (h_isend&&(v_count==v_stop-1));
always@(posedge CLK) if(h_isend) v_count <= v_isend ? 1'h0 : v_count+1'h1;
reg v_sync = 0;
always@(posedge CLK) if(h_isend) v_sync <= ((v_pulse<=v_count)&&(v_count<=v_stop));

wire v_enable = ((v_blank<=v_count)&&(v_count <= v_disp-1));
wire [9:0] v_pos=v_count-v_blank;
reg hv_enable = 0;
always@(posedge CLK) if(c_isend) hv_enable <= h_enable && v_enable;
assign LCD_VSYNC = v_sync;
assign LCD_DE = hv_enable;

/////////////////////////////
// audio buffer write
/////////////////////////////
localparam audio_buf_bit = 12;
localparam audio_buf_size = 2**audio_buf_bit;

reg [audio_buf_bit+1:0] audio_buf_wr_adr = 0;
always@(posedge CLK) if(AUDIORDY && AUDIORUN ) audio_buf_wr_adr <= audio_buf_wr_adr+1'h1;
wire [audio_buf_bit-1:0] audio_buf_wr_adr_hi = audio_buf_wr_adr[audio_buf_bit+1:2];
wire [1:0] audio_buf_wr_adr_lo = audio_buf_wr_adr[1:0];

reg signed [17:0] audio_buf0[0:audio_buf_size-1];
reg signed [17:0] audio_buf1[0:audio_buf_size-1];
reg signed [17:0] audio_buf2[0:audio_buf_size-1];
reg signed [17:0] audio_buf3[0:audio_buf_size-1];
always@(posedge CLK) if(AUDIORDY && AUDIORUN && audio_buf_wr_adr_lo==2'd0) audio_buf0[audio_buf_wr_adr_hi] <=AUDIO;
always@(posedge CLK) if(AUDIORDY && AUDIORUN && audio_buf_wr_adr_lo==2'd1) audio_buf1[audio_buf_wr_adr_hi] <=AUDIO;
always@(posedge CLK) if(AUDIORDY && AUDIORUN && audio_buf_wr_adr_lo==2'd2) audio_buf2[audio_buf_wr_adr_hi] <=AUDIO;
always@(posedge CLK) if(AUDIORDY && AUDIORUN && audio_buf_wr_adr_lo==2'd3) audio_buf3[audio_buf_wr_adr_hi] <=AUDIO;

////////////////////////////////
// sin() and cos() from rotation based NCO 'nco_45' 
////////////////////////////////
// nco_45 nco(.CK(CLK), .START(h_count==0), .v_pos(v_pos[8:0]), .cos0(cos0), .sin0(sin0), .cos1(cos1), .sin1(sin1));
wire signed [17:0] cos0, sin0, cos1, sin1, cos2, sin2, cos3, sin3;
nco_4ch nco( .CK(CLK), .START(h_count==0), .v_pos(v_pos[8:0]), .mode_4800(mode_4800),
    .cos0(cos0), .sin0(sin0), .cos1(cos1), .sin1(sin1), .cos2(cos2), .sin2(sin2), .cos3(cos3), .sin3(sin3) );

reg signed [17:0] cos0_multin, sin0_multin, cos1_multin, sin1_multin;
reg signed [17:0] cos2_multin, sin2_multin, cos3_multin, sin3_multin;
always@(posedge CLK) begin 
    cos0_multin <= cos0; sin0_multin <= sin0; cos1_multin<=cos1; sin1_multin<=sin1;
    cos2_multin <= cos2; sin2_multin <= sin2; cos3_multin<=cos3; sin3_multin<=sin3;
end

// dosc_2ch_fc2400_fs5859 nco(.CK(CLK), .START(h_count==0), .v_pos(v_pos[8:0]), .cos0(cos0), .sin0(sin0), .cos1(cos1), .sin1(sin1)); 
/////////////////////////////////
// audio buffer read
/////////////////////////////////
reg [audio_buf_bit-1:0] audio_buf_rd_adr = 0;
always@(posedge CLK) audio_buf_rd_adr <= h_isnoinpend ? audio_buf_wr_adr_hi+2'd2+9'd400: audio_buf_rd_adr+1'd1;
reg signed [17:0] audio_ramout0, audio_ramout1, audio_ramout2, audio_ramout3;
always@(posedge CLK) audio_ramout0 <= audio_buf0[audio_buf_rd_adr]; // check
always@(posedge CLK) audio_ramout1 <= audio_buf1[audio_buf_rd_adr]; // check
always@(posedge CLK) audio_ramout2 <= audio_buf2[audio_buf_rd_adr]; // check
always@(posedge CLK) audio_ramout3 <= audio_buf3[audio_buf_rd_adr]; // check

reg signed [17:0] audio_multin0=0, audio_multin1=0;
always@(posedge CLK) audio_multin0 <= audio_ramout0; // check
always@(posedge CLK) audio_multin1 <= audio_ramout1; // check
reg signed [17:0] audio_multin2=0, audio_multin3=0;
always@(posedge CLK) audio_multin2 <= audio_ramout2; // check
always@(posedge CLK) audio_multin3 <= audio_ramout3; // check

/////////////////////////////////////////////////////////////
// complex CIC filter, used as WINDOW FUNCTION
/////////////////////////////////////////////////////////////
localparam B_abit = 5;
localparam B_fifomax = 2**B_abit-1;
localparam B_dbit = 54; // 36+3+B_abit;
wire [B_abit-1:0] fifo_idx = h_count[B_abit-1:0];
localparam cic_out_bitlow = 10;
localparam cic_out_bithi = cic_out_bitlow+17;

reg signed [B_dbit-1:0] real_I00=0, real_I01=0, real_I0=0;
reg signed [B_dbit-1:0] real_I1=0, real_I2=0, real_I3=0, real_I4=0;
reg signed [B_dbit-1:0] real_fifo[0:B_fifomax];
reg signed [B_dbit-1:0] real_B0=0, real_B1=0, real_B2=0, real_B3=0;
reg signed [B_dbit-1:0] real_D0=0, real_D1=0, real_D2=0, real_D3=0, real_D4=0;


always@(posedge CLK) real_I00 <= cos0_multin*audio_multin0+cos1_multin*audio_multin1;
always@(posedge CLK) real_I01 <= cos2_multin*audio_multin2+cos3_multin*audio_multin3;
always@(posedge CLK) real_I0  <= (real_I00+real_I01)>>>1;

always@(posedge CLK) real_I1 <= real_I1+$signed(real_I0>>>(B_abit+2));
always@(posedge CLK) real_I2 <= real_I2+$signed(real_I1>>>(B_abit+2));
always@(posedge CLK) real_I3 <= real_I3+$signed(real_I2>>>(B_abit+3));
always@(posedge CLK) real_I4 <= real_I4+$signed(real_I3>>>(B_abit+3));

always@(posedge CLK) if(c_S[0]) real_B0 <= real_fifo[fifo_idx];
always@(posedge CLK) if(c_S[0]) real_B1 <= real_D1;
always@(posedge CLK) if(c_S[0]) real_B2 <= real_D2;
always@(posedge CLK) if(c_S[0]) real_B3 <= real_D3;
always@(posedge CLK) if(c_S[0]) real_D0 <= real_I4;
always@(posedge CLK) if(c_S[0]) real_D1 <= real_D0-real_B0;
always@(posedge CLK) if(c_S[0]) real_D2 <= real_D1-real_B1;
always@(posedge CLK) if(c_S[0]) real_D3 <= real_D2-real_B2;
always@(posedge CLK) if(c_S[0]) real_D4 <= real_D3-real_B3;
always@(posedge CLK) if(c_S[0]) real_fifo[fifo_idx] <= real_I4;

wire [17:0] real_out = real_D4[17:0];

reg signed [B_dbit-1:0] imag_I00=0, imag_I01=0, imag_I0=0;
reg signed [B_dbit-1:0] imag_I1=0, imag_I2=0, imag_I3=0, imag_I4=0;
reg signed [B_dbit-1:0] imag_fifo[0:B_fifomax];
reg signed [B_dbit-1:0] imag_B0=0, imag_B1=0, imag_B2=0, imag_B3=0;
reg signed [B_dbit-1:0] imag_D0=0, imag_D1=0, imag_D2=0, imag_D3=0, imag_D4=0;

always@(posedge CLK) imag_I00 <= sin0_multin*audio_multin0+sin1_multin*audio_multin1;
always@(posedge CLK) imag_I01 <= sin2_multin*audio_multin2+sin3_multin*audio_multin3;
always@(posedge CLK) imag_I0  <= (imag_I00+imag_I01)>>>1;

always@(posedge CLK) imag_I1 <= imag_I1+$signed(imag_I0>>>(B_abit+2));
always@(posedge CLK) imag_I2 <= imag_I2+$signed(imag_I1>>>(B_abit+2));
always@(posedge CLK) imag_I3 <= imag_I3+$signed(imag_I2>>>(B_abit+3));
always@(posedge CLK) imag_I4 <= imag_I4+$signed(imag_I3>>>(B_abit+3));

always@(posedge CLK) if(c_S[0]) imag_B0 <= imag_fifo[fifo_idx];
always@(posedge CLK) if(c_S[0]) imag_B1 <= imag_D1;
always@(posedge CLK) if(c_S[0]) imag_B2 <= imag_D2;
always@(posedge CLK) if(c_S[0]) imag_B3 <= imag_D3;
always@(posedge CLK) if(c_S[0]) imag_D0 <= imag_I4; // take care, vary on every CLOCK
always@(posedge CLK) if(c_S[0]) imag_D1 <= imag_D0-imag_B0;
always@(posedge CLK) if(c_S[0]) imag_D2 <= imag_D1-imag_B1;
always@(posedge CLK) if(c_S[0]) imag_D3 <= imag_D2-imag_B2;
always@(posedge CLK) if(c_S[0]) imag_D4 <= imag_D3-imag_B3;
always@(posedge CLK) if(c_S[0]) imag_fifo[fifo_idx] <= imag_I4;

wire [17:0] imag_out = imag_D4[17:0];
/////////////////////////////////////////////////////////////
// abs(signal power)^2 = real*real+imag*imag 
/////////////////////////////////////////////////////////////
localparam df_hib = 41; //41
localparam df_lob = df_hib-18+1;
localparam sq_bit = 36;
wire signed [17:0] realD0_r = real_out; // $signed(real_out[df_hib:df_lob]);
wire signed [17:0] imagD0_r = imag_out; // $signed(imag_out[df_hib:df_lob]);
reg [sq_bit-1:0] sumsq = 0;
always@(posedge CLK) if(c_S[3]) sumsq <= realD0_r*realD0_r + imagD0_r*imagD0_r;

/////////////////////////
// log image out
/////////////////////////
localparam sq_hib = 34;
reg [5:0] blog;
always@(posedge CLK) if(c_isend) blog <= {log2_17_5(sumsq[34:18]), 1'b0};
/*
always@(posedge CLK) if(c_isend) begin
    if (         sumsq[sq_hib   :sq_hib- 1]==2'b11 ) begin blog <= 62;
    end else if( sumsq[sq_hib   :sq_hib- 1]==2'b10 ) begin blog <= 60;
    end else if( sumsq[sq_hib- 1:sq_hib- 2]==2'b11 ) begin blog <= 58;
    end else if( sumsq[sq_hib- 1:sq_hib- 2]==2'b10 ) begin blog <= 56;
    end else if( sumsq[sq_hib- 2:sq_hib- 3]==2'b11 ) begin blog <= 54;
    end else if( sumsq[sq_hib- 2:sq_hib- 3]==2'b10 ) begin blog <= 52;
    end else if( sumsq[sq_hib- 3:sq_hib- 4]==2'b11 ) begin blog <= 50;
    end else if( sumsq[sq_hib- 3:sq_hib- 4]==2'b10 ) begin blog <= 48;
    end else if( sumsq[sq_hib- 4:sq_hib- 5]==2'b11 ) begin blog <= 46;
    end else if( sumsq[sq_hib- 4:sq_hib- 5]==2'b10 ) begin blog <= 44;
    end else if( sumsq[sq_hib- 5:sq_hib- 6]==2'b11 ) begin blog <= 42;
    end else if( sumsq[sq_hib- 5:sq_hib- 6]==2'b10 ) begin blog <= 40;
    end else if( sumsq[sq_hib- 6:sq_hib- 7]==2'b11 ) begin blog <= 38;
    end else if( sumsq[sq_hib- 6:sq_hib- 7]==2'b10 ) begin blog <= 36;
    end else if( sumsq[sq_hib- 7:sq_hib- 8]==2'b11 ) begin blog <= 34;
    end else if( sumsq[sq_hib- 7:sq_hib- 8]==2'b10 ) begin blog <= 32;
    end else if( sumsq[sq_hib- 8:sq_hib- 9]==2'b11 ) begin blog <= 30;
    end else if( sumsq[sq_hib- 8:sq_hib- 9]==2'b10 ) begin blog <= 28;
    end else if( sumsq[sq_hib- 9:sq_hib-10]==2'b11 ) begin blog <= 26;
    end else if( sumsq[sq_hib- 9:sq_hib-10]==2'b10 ) begin blog <= 24;
    end else if( sumsq[sq_hib-10:sq_hib-11]==2'b11 ) begin blog <= 22;
    end else if( sumsq[sq_hib-10:sq_hib-11]==2'b10 ) begin blog <= 20;
    end else if( sumsq[sq_hib-11:sq_hib-12]==2'b11 ) begin blog <= 18;
    end else if( sumsq[sq_hib-11:sq_hib-12]==2'b10 ) begin blog <= 16;
    end else if( sumsq[sq_hib-12:sq_hib-13]==2'b11 ) begin blog <= 14;
    end else if( sumsq[sq_hib-12:sq_hib-13]==2'b10 ) begin blog <= 12;
    end else if( sumsq[sq_hib-13:sq_hib-14]==2'b11 ) begin blog <= 10;
    end else if( sumsq[sq_hib-13:sq_hib-14]==2'b10 ) begin blog <=  8;
    end else if( sumsq[sq_hib-14:sq_hib-15]==2'b11 ) begin blog <=  6;
    end else if( sumsq[sq_hib-14:sq_hib-15]==2'b10 ) begin blog <=  4;
    end else if( sumsq[sq_hib-15:sq_hib-16]==2'b11 ) begin blog <=  2;
    // end else if( sumsq[sq_hib-15:sq_hib-16]==2'b10 ) begin blog <=  0;
    end else begin blog <= 0;
    end
end
*/


reg gridenout = 0;
reg gridpixout = 0;
grid_pixgen gp( .CK(CLK), .EN(c_S), .v_pos(v_pos), .h_pos(h_pos), .mode_4800(mode_4800), .enout(gridenout), .pixout(gridpixout) );

reg [15:0] LCD_RGB565_r = 0;
assign LCD_RGB565=LCD_RGB565_r;

always@(posedge CLK) if(c_S[3]) LCD_RGB565_r <= gridpixout ? 16'h7bef : {blog[5:1], blog[5:0], blog[5:1]}; 


endmodule



