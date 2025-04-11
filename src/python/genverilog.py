#
#
#
#
from logging.handlers import DatagramHandler
from tkinter.messagebox import NO
import numpy as np
def rom_20220912( modulename, garray, abit=1, dbit=1, binary=False ):
    abit = int(max(abit, (int(np.ceil(np.log2(len(garray)))))))
    dbit = int(max(dbit, (int(np.ceil(np.log2(np.max(garray)))))))
    retval = ''
    retval += (
        f'module {modulename} (clock,ce,oce,reset,addr,dataout);\n'
        f'\tinput clock,ce,oce,reset;\n'
        f'\tinput [{abit-1}:0] addr;\n'
        f'\toutput [{dbit-1}:0] dataout;\n'
        f'\treg [{dbit-1}:0] dataout;\n'
        f'\talways @(posedge clock or posedge reset) begin\n'
        f'\t\tif(reset) begin\n'
        f'\t\t\tdataout <= 0;\n'
        f'\t\tend else begin\n'
        f'\t\t\tif (ce & oce) begin\n'
        f'\t\t\t\tcase (addr)\n'
    )
    if binary:
        for adr, d in enumerate(garray):
            retval += ( f'\t\t\t\t\t{abit}\'d{adr:04d}: dataout<={dbit}\'b{d:0{dbit:d}b};\n' )
    else:
        for adr, d in enumerate(garray):
            retval += ( f'\t\t\t\t\t{abit}\'d{adr:04d}: dataout<={dbit}\'d{d:08d};\n' )
    retval += (
        f'\t\t\t\tendcase\n'
        f'\t\t\tend\n'
        f'\t\tend\n'
        f'\tend\n'
        f'endmodule\n\n'
        )
    return retval

#
import numpy as np
def rom( modulename, garray, abit=1, dbit=1, mode='decimal', fill=0 ):
    abit = int(max(abit, (int(np.ceil(np.log2(len(garray)))))))
    dbit = int(max(dbit, (int(np.ceil(np.log2(np.max(garray)))))))
    retval = ''
    retval += (
        f'module {modulename} (clock,ce,oce,reset,addr,dataout);\n'
        f'\tinput clock,ce,oce,reset;\n'
        f'\tinput [{abit-1}:0] addr;\n'
        f'\toutput [{dbit-1}:0] dataout;\n'
        f'\treg [{dbit-1}:0] dataout;\n'
        f'\talways @(posedge clock or posedge reset) begin\n'
        f'\t\tif(reset) begin\n'
        f'\t\t\tdataout <= 0;\n'
        f'\t\tend else begin\n'
        f'\t\t\tif (ce & oce) begin\n'
        f'\t\t\t\tcase (addr)\n'
    )
    datalen = len(garray)
    for adr in range( 2**abit ):
            if adr < datalen:
                data = garray.ravel()[adr]
            elif fill is not None:
                data = fill
            else:
                DatagramHandler = None

            if (mode == 'binary' or mode =='bin' ):
                retval += ( f'\t\t\t\t\t{abit}\'d{adr:04d}: dataout<={dbit}\'b{data:0{dbit:d}b};\n' )
            elif (mode == 'hexadecimal' or mode=='hexa' or mode=='hex'):
                hdigit = f'0{((dbit-1)>>2)+1}x'
                adigit = f'0{((abit-1)>>2)+1}x'
                retval += ( f'\t\t\t\t\t{abit}\'h{adr:{adigit}}: dataout<={dbit}\'h{data:{hdigit}};\n' )
            else:
                retval += ( f'\t\t\t\t\t{abit}\'d{adr:04d}: dataout<={dbit}\'d{data:08d};\n' )

    retval += (
        f'\t\t\t\tendcase\n'
        f'\t\t\tend\n'
        f'\t\tend\n'
        f'\tend\n'
        f'endmodule\n\n'
        )
    return retval


def simple_rom( modulename, garray, abit=1, dbit=1, mode='decimal', fill=None ):
    abit = int(max(abit, (int(np.ceil(np.log2(len(garray)))))))
    dbit = int(max(dbit, (int(np.ceil(np.log2(np.max(garray)))))))
    retval = ''
    retval += (
        f'module {modulename} (clock,addr,dataout);\n'
        f'\tinput clock;\n'
        f'\tinput [{abit-1}:0] addr;\n'
        f'\toutput reg signed [{dbit-1}:0] dataout;\n'
        f'\talways @(posedge clock) begin\n'
        f'\t\tcase (addr)\n'
    )
    datalen = len(garray)
    for adr in range( 2**abit ):
            if adr < datalen:
                data = garray.ravel()[adr]
            elif fill is not None:
                data = fill
            else:
                data = None
            pass
    
            if data is None:
                pass # do nothing
            elif (mode == 'binary' or mode =='bin' ):
                retval += ( f'\t\t\t{abit}\'d{adr:04d}: dataout<={dbit}\'b{data:0{dbit:d}b};\n' )
            elif (mode == 'hexadecimal' or mode=='hexa' or mode=='hex'):
                hdigit = f'0{((dbit-1)>>2)+1}x'
                adigit = f'0{((abit-1)>>2)+1}x'
                retval += ( f'\t\t\t{abit}\'h{adr:{adigit}}: dataout<={dbit}\'h{data:{hdigit}};\n' )
            else:
                retval += ( f'\t\t\t{abit}\'d{adr:04d}: dataout<={dbit}\'d{data:08d};\n' )
            pass
    retval += (
        f'\t\tendcase\n'
        f'\tend\n'
        f'endmodule\n\n'
        )
    return retval

#
#
# no good
def _dprom( modulename, garray, adrbits=10, databits=18, binary=False ):
    retval = ''
    retval += (
        f'module {modulename} (clka,cea,addra,dataouta, clkb,ceb,addrb,dataoutb, reset );\n'
        f'\tinput clka,cea,clkb,ceb, reset;\n'
        f'\tinput [{adrbits-1}:0] addra;\n'
        f'\tinput [{adrbits-1}:0] addrb;\n'
        f'\toutput reg [{databits-1}:0] dataouta;\n'
        f'\toutput reg [{databits-1}:0] dataoutb;\n'
        f'\treg [(2**{databits})-1:0] mem[0:(2**{adrbits})-1];\n'
        f'\tinitial begin\n'
    )
    if binary:
        for adr, d in enumerate(garray):
            retval += ( f'\t\tmem[{adrbits}\'d{adr:04d}] = {databits}\'b{d:0{databits:d}b};\n' )
    else:
        for adr, d in enumerate(garray):
            retval += ( f'\t\tmem[{adrbits}\'d{adr:04d}] = {databits}\'d{d:08d};\n' )
    retval += (
        f'\tend\n'
        f'\talways @(posedge clka) begin\n'
        f'\t\tif (cea) begin\n'
        f'\t\t\tdataouta <= mem[addra];\n'
        f'\t\tend\n'
        f'\tend\n'
        f'\talways @(posedge clkb) begin\n'
        f'\t\tif (ceb) begin\n'
        f'\t\t\tdataoutb <= mem[addrb];n'
        f'\t\tend\n'
        f'\tend\n'
        f'endmodule\n\n'
    )
    return retval
#

def rom_write( fname, modulename, garray, abit=9, dbit=18, mode='dec', fill=None ):
    with open ( fname, 'w' ) as f:
        f.write(rom( modulename, garray, abit, dbit, mode, fill )) 

def simple_rom_write( fname, modulename, garray, abit=9, dbit=18, mode='dec', fill=None ):
    with open ( fname, 'w' ) as f:
        f.write(simple_rom( modulename, garray, abit, dbit, mode, fill )) 
        
def _unused_dprom_write( fname, modulename, garray, adrbits=9, databits=18, mode='dec' ):
    with open ( fname, 'w' ) as f:
        f.write(_dprom( modulename, garray, adrbits, databits, mode )) 

