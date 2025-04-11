/////////////////////////
// log image out
/////////////////////////

function [4:0] log2_17_5( input [16:0] a );
    casex(a)
        17'b1_1xxx_xxxx_xxxx_xxxx: log2_17_5 = 31;
        17'b1_0xxx_xxxx_xxxx_xxxx: log2_17_5 = 30;
        17'b0_11xx_xxxx_xxxx_xxxx: log2_17_5 = 29;
        17'b0_10xx_xxxx_xxxx_xxxx: log2_17_5 = 28;
        17'b0_011x_xxxx_xxxx_xxxx: log2_17_5 = 27;
        17'b0_010x_xxxx_xxxx_xxxx: log2_17_5 = 26;
        17'b0_0011_xxxx_xxxx_xxxx: log2_17_5 = 25;
        17'b0_0010_xxxx_xxxx_xxxx: log2_17_5 = 24;
        17'b0_0001_1xxx_xxxx_xxxx: log2_17_5 = 23;
        17'b0_0001_0xxx_xxxx_xxxx: log2_17_5 = 22;
        17'b0_0000_11xx_xxxx_xxxx: log2_17_5 = 21;
        17'b0_0000_10xx_xxxx_xxxx: log2_17_5 = 20;
        17'b0_0000_011x_xxxx_xxxx: log2_17_5 = 19;
        17'b0_0000_010x_xxxx_xxxx: log2_17_5 = 18;
        17'b0_0000_0011_xxxx_xxxx: log2_17_5 = 17;
        17'b0_0000_0010_xxxx_xxxx: log2_17_5 = 16;
        17'b0_0000_0001_1xxx_xxxx: log2_17_5 = 15;
        17'b0_0000_0001_0xxx_xxxx: log2_17_5 = 14;
        17'b0_0000_0000_11xx_xxxx: log2_17_5 = 13;
        17'b0_0000_0000_10xx_xxxx: log2_17_5 = 12;
        17'b0_0000_0000_011x_xxxx: log2_17_5 = 11;
        17'b0_0000_0000_010x_xxxx: log2_17_5 = 10;
        17'b0_0000_0000_0011_xxxx: log2_17_5 =  9;
        17'b0_0000_0000_0010_xxxx: log2_17_5 =  8;
        17'b0_0000_0000_0001_1xxx: log2_17_5 =  7;
        17'b0_0000_0000_0001_0xxx: log2_17_5 =  6;
        17'b0_0000_0000_0000_11xx: log2_17_5 =  5;
        17'b0_0000_0000_0000_10xx: log2_17_5 =  4;
        17'b0_0000_0000_0000_011x: log2_17_5 =  3;
        17'b0_0000_0000_0000_010x: log2_17_5 =  2;
        17'b0_0000_0000_0000_0011: log2_17_5 =  1;
        default:                   log2_17_5 =  0;    
    endcase
endfunction


