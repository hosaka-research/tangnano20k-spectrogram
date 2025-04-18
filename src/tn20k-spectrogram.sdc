//Copyright (C)2014-2021 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.6.02 Beta
//Created Time: 2021-11-04 19:03:59
//
// clock input is 27MHz 
create_clock -name XTAL_IN -period 37.037 -waveform {0 18.518} [get_ports {XTAL_IN}] -add
//
// LCD Clock output: 22.5MHz
//create_clock -name LCD_CLK -period 30.03 -waveform {0 15.015} [get_ports {LCD_CLK}] -add
create_clock -name LCD_CLK -period 44.44 -waveform {0 22.22} [get_ports {LCD_CLK}] -add
