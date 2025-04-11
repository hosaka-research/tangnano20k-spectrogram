del nco_4ch_tb.vvp nco_4ch_tb.vcd nco_4ch_tb.err
iverilog -g2012 -onco_4ch_tb.vvp nco_4ch_tb.v nco_4ch.v nco_rom_4ch_fc2400_fs5859.v nco_rom_4ch_fc2400_fs11718.v nco_rom_4ch_fc4800_fs11718.v 2>> nco_4ch_tb.err
vvp nco_4ch_tb.vvp 2>> nco_4ch_tb.err
gtkwave nco_4ch_tb.vcd



