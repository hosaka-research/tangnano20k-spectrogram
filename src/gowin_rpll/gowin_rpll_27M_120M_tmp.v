//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8.09 Education
//Part Number: GW2AR-LV18QN88PC8/I7
//Device: GW2AR-18C
//Created Time: Mon Apr 07 07:50:19 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_rPLL_27M_120M your_instance_name(
        .clkout(clkout_o), //output clkout
        .lock(lock_o), //output lock
        .clkin(clkin_i) //input clkin
    );

//--------Copy end-------------------
