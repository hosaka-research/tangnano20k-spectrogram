
# tangnano20k-spectrogram
Realtime spectrogram on tang nano 20k

## BOM
tang nano 20k with header [https://ja.aliexpress.com/item/1005005581148230.html]

5inch LCD Display for Tang Nano [https://ja.aliexpress.com/item/1005005581148230.html]

Silicon I2S microphone module [https://www.switch-science.com/products/8792]

    [tang nano 20k]------------[I2S digital microphone]
    [J5-15, GND]---------------[pin 2 G]
    [J5-16, 3V3]---------------[pin 1 V]
    [J5-17, PIN72_HSPI_DIN1]-->[pin 3 WS] channel id from mic
    [J5-18, PIN71_HSPI_DIN0]-->[pin 4 LR] always 0 from tangnano
    [J5-19, PIN53_EDID_CLK]--->[pin 5 CK] 3MHz ck out from tangnano
    [J5-20, PIN51_EDID_DAT]<---[pin 6 DA] audio dataout from mic 

Breadboard [https://akizukidenshi.com/catalog/g/gP-12366/]

DO NOT CONNECT to tang nano 20k AUDIO OUTPUT I2S, these are not input
[tang nano 20k]
[J5-8 PIN67_I2S_DIN], [J5-7 PIN45_I2S_BCLK], [J5-11 PIN55_I2S_LRCK]

