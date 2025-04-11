del cic_pdm_mic_90M_3M_6k_tb.vvp cic_pdm_mic_90M_3M_6k_tb.vcd cic_pdm_mic_90M_3M_6k_tb.err
iverilog -ocic_pdm_mic_90M_3M_6k_tb.vvp ..\cic_pdm_mic.v 2> cic_pdm_mic_90M_3M_6k_tb.err
vvp cic_pdm_mic_90M_3M_6k_tb.vvp 2>> cic_pdm_mic_90M_3M_6k_tb.err
gtkwave cic_pdm_mic_90M_3M_6k_tb.vcd

