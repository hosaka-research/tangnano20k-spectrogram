
import numpy as np
import matplotlib.pyplot as plt
import genverilog

A4_Hz=440.0
MIDINO_A4=69
# fs_Hz = 6000 # for PDM digital microphone
fs_Hz = 5859.375

def MIDINO_Hz( midino ):
    return (A4_Hz*pow(2.0,((midino-MIDINO_A4)/12.0)))

class nco_complex:
    def __init__( self, fc_Hz, fs_Hz, para=4 ):
        self.fc_Hz = np.array(fc_Hz)
        self.shape = self.fc_Hz.shape+(para,)
        self.fs_Hz = fs_Hz
        self.para = para
        rot_rad = 2.0*np.pi*self.fc_Hz/fs_Hz
        self.init_rot = np.exp( rot_rad*1j )
        self.para_rot = np.exp( para*rot_rad*1j )
        self.d = np.zeros( (len(fc_Hz), para), dtype=np.complex64 )
        for pidx in range(para):
            self.d[:,pidx] = self.init_rot**pidx
        
    def __call__( self ):
        self.d *= self.para_rot[:,None]
        return self.d

    def get_array( self, outsize ):
        retval = np.zeros( self.shape+(outsize,), dtype=np.complex64 )
        for idx in range(outsize):
            retval[:,:,idx] = self()
        return retval
    
    def plot( self, outsize, ch=None ):
        arr = self.get_array( outsize )
        xaxis = np.arange(outsize)
        if ch is None:
            fig, ax = plt.subplots( min( self.shape[0], 16 ), 1 )
            for axidx, crntax in enumerate(ax):
                d = arr[axidx,:,:].transpose().ravel()
                crntax.plot( d.real )
                crntax.plot( d.imag )
            plt.show( block=True )
        else:
            fig, ax = plt.subplots( 4, 1 )
            for axidx, crntax in enumerate(ax):
                d = arr[ch,axidx,:]
                crntax.plot( d.real )
                crntax.plot( d.imag )
            plt.show( block=True )

class nco_float(nco_complex):
    def __init__( self, fc_Hz, fs_Hz, para=4 ):
        super().__init__(fc_Hz, fs_Hz, para)
        self.init_cos = np.array(self.init_rot.real, dtype=np.float32 )
        self.init_sin = np.array(self.init_rot.imag, dtype=np.float32 )
        self.para_cos = np.array(self.para_rot.real, dtype=np.float32 )
        self.para_sin = np.array(self.para_rot.imag, dtype=np.float32 )
        self.d_cos = np.zeros( self.shape, dtype=np.float32 ) 
        self.d_sin = np.zeros( self.shape, dtype=np.float32 ) 
        for i in range(para):
            if i == 0: 
                self.d_cos[:,i] = 1.0
                self.d_sin[:,i] = 0.0
            else:
                self.d_cos[:,i] = (self.d_cos[:,i-1]*self.init_cos - self.d_sin[:,i-1]*self.init_sin)
                self.d_sin[:,i] = (self.d_cos[:,i-1]*self.init_sin + self.d_sin[:,i-1]*self.init_cos)
        return
    
    def dump( self, path=None):
        if path is None : return
        rom_data = np.stack( (self.init_cos, self.init_sin, self.para_cos, self.para_sin), axis=-1 )

    def __call__( self ):
        self.d_cos, self.d_sin = (
            (self.d_cos*self.para_cos[:,None] - self.d_sin*self.para_sin[:,None]),
            (self.d_cos*self.para_sin[:,None] + self.d_sin*self.para_cos[:,None])    
        )
        return self.d_cos, self.d_sin

    def get_array( self, outsize ):
        retcos = np.zeros( self.shape+(outsize,), dtype=np.float32 )
        retsin = np.zeros( self.shape+(outsize,), dtype=np.float32 )
        for idx in range(outsize):
            (retcos[:,:,idx], retsin[:,:,idx]) = self()
        return retcos, retsin
    
    def plot( self, outsize, ch=None ):
        dcos, dsin = self.get_array( outsize )
        xaxis = np.arange(outsize)
        if ch is None:
            fig, ax = plt.subplots( min( self.shape[0], 16 ), 1 )
            for axidx, crntax in enumerate(ax):
                crntax.plot( dcos[axidx,:,:].transpose().ravel() )
                crntax.plot( dsin[axidx,:,:].transpose().ravel() )
        else:
            fig, ax = plt.subplots( 4, 1 )
            for axidx, crntax in enumerate(ax):
                crntax.plot( dcos[ch,axidx,:] )
                crntax.plot( dsin[ch,axidx,:] )
        plt.show( block=True )

class nco_fixed18(nco_complex):
    def __init__( self, fc_Hz, fs_Hz, para=4 ):
        super().__init__(fc_Hz, fs_Hz, para)
        self.init_cos = np.array(self.init_rot.real*(2**17), dtype=np.int64 )
        self.init_sin = np.array(self.init_rot.imag*(2**17), dtype=np.int64 )
        self.para_cos = np.array(self.para_rot.real*(2**17), dtype=np.int64 )
        self.para_sin = np.array(self.para_rot.imag*(2**17), dtype=np.int64 )
        #print(self.shape)
        self.d_cos = np.zeros( self.shape, dtype=np.int64 ) 
        self.d_sin = np.zeros( self.shape, dtype=np.int64 )
        for i in range(para):
            if i == 0: 
                self.d_cos[:,i] = 0x1ffff
                self.d_sin[:,i] = 0x0
                print( np.atan2( self.d_sin[1,i], self.d_cos[1,i] ) )
            else:
                self.d_cos[:,i] = (self.d_cos[:,i-1]*self.init_cos - self.d_sin[:,i-1]*self.init_sin)>>17
                self.d_sin[:,i] = (self.d_cos[:,i-1]*self.init_sin + self.d_sin[:,i-1]*self.init_cos)>>17
                print( np.atan2( self.d_sin[1,i], self.d_cos[1,i] ) )
        self.cos_rom_data = np.stack(
            (self.d_cos[:,1]%(2**18), self.d_cos[:,2]%(2**18),
             self.d_cos[:,3]%(2**18), self.para_cos%(2**18)), axis=-1 ).copy()
        self.sin_rom_data = np.stack(
            (self.d_sin[:,1]%(2**18), self.d_sin[:,2]%(2**18),
             self.d_sin[:,3]%(2**18), self.para_sin%(2**18)), axis=-1 ).copy()
        self.rom_data = np.bitwise_or( self.cos_rom_data, self.sin_rom_data << 18 ).copy()

    def dumpcos( self, path=None, modulename=None ):
        if path is None or modulename is None: return
        genverilog.simple_rom_write( path, modulename, self.cos_rom_data.ravel(), dbit=18, abit=11, mode='hex' )

    def dumpsin( self, path=None, modulename=None ):
        if path is None or modulename is None: return
        genverilog.simple_rom_write( path, modulename, self.sin_rom_data.ravel(), dbit=18, abit=11, mode='hex' )

    def dumpcossin( self, path=None, modulename=None ):
        if path is None or modulename is None: return
        genverilog.simple_rom_write( path, modulename, self.rom_data.ravel(), dbit=36, abit=11, mode='hex', fill=0 )
        if False:
            for i in range(self.para):
                print( f'before {self.d_cos[0,i]=}, {self.d_sin[0,i]=}' )
                if i == 0: 
                    self.d_cos[:,i] = 0x1ffff
                    self.d_sin[:,i] = 0x0
                else:
                    self.d_cos[:,i] = self.uint18_int18(self.cos_rom_data[:,i-1])
                    self.d_sin[:,i] = self.uint18_int18(self.sin_rom_data[:,i-1])
                print( f'after  {self.d_cos[0,i]=}, {self.d_sin[0,i]=}')
                #print( np.atan2( self.d_sin[1,i], self.d_cos[1,i] ) )

    def __call__( self ):
        self.d_cos, self.d_sin = (
            (self.d_cos*self.para_cos[:,None] - self.d_sin*self.para_sin[:,None])>>17,
            (self.d_cos*self.para_sin[:,None] + self.d_sin*self.para_cos[:,None])>>17    
        )
        return self.d_cos, self.d_sin

    def uint18_int18( self, data ):
        return np.where( 2**17<=data, data-2**18, data )

    def get_array( self, outsize ):
        retcos = np.zeros( self.shape+(outsize,), dtype=np.int64 )
        retsin = np.zeros( self.shape+(outsize,), dtype=np.int64 )
        for idx in range(outsize):
            (retcos[:,:,idx],retsin[:,:,idx]) = self()
        return retcos, retsin
    
    def plot( self, outsize, ch=None ):
        dcos, dsin = self.get_array( outsize )
        xaxis = np.arange(outsize)
        if ch is None:
            fig, ax = plt.subplots( min( self.shape[0], 16 ), 1 )
            for axidx, crntax in enumerate(ax):
                crntax.plot( dcos[axidx,:,:].transpose().ravel()*(2**-17) )
                crntax.plot( dsin[axidx,:,:].transpose().ravel()*(2**-17) )
        else:
            fig, ax = plt.subplots( 4, 1 )
            for axidx, crntax in enumerate(ax):
                crntax.plot( dcos[ch,axidx,:]*(2**-17) )
                crntax.plot( dsin[ch,axidx,:]*(2**-17) )
        plt.show( block=True )

class dosc:
    def __init__( self, fc_Hz, fs_Hz, para=4 ):
        self.fc_Hz = np.array(fc_Hz)
        self.shape = self.fc_Hz.shape+(para,)
        self.fs_Hz = fs_Hz
        self.d_omega = 2.0*np.pi*self.fc_Hz/fs_Hz
        self.k = 2.0*np.cos(self.d_omega*para)
        dM1_omega = np.einsum( 'i,j', self.d_omega, np.arange(0*para,1*para,1) )
        d_omega = np.einsum( 'i,j', self.d_omega, np.arange(1*para,2*para,1) )
        self.init_dM1 = np.exp( 1j*dM1_omega )
        self.init_d   = np.exp( 1j*d_omega )
        pass

class dosc_complex(nco_complex):
    def __init__( self, fc_Hz, fs_Hz, para=4 ):
        self.i = dosc( fc_Hz, fs_Hz, para )
        self.shape = self.i.shape
        self.dM1 = self.i.init_dM1
        self.d = self.i.init_d
        self.k = self.i.k
        pass

    def __call__( self ):
        print(self.d[0,0].real, self.dM1[0,0].real, self.k[0] )
        out = self.d*self.k[:,None]-self.dM1
        self.dM1 = self.d
        self.d = out
        print(self.d[0,0].real, self.dM1[0,0].real )
        return out
    
class dosc_float(nco_float):
    def __init__( self, fc_Hz, fs_Hz, para=4 ):
        self.i = dosc( fc_Hz, fs_Hz, para )
        self.shape = self.i.shape
        self.k = self.i.k
        self.dM1_cos = self.i.init_dM1.real.copy()
        self.dM1_sin = self.i.init_dM1.imag.copy()
        self.d_cos = self.i.init_d.real.copy()
        self.d_sin = self.i.init_d.imag.copy()

        print(self.dM1_cos)
        print(self.dM1_sin)
        print(self.d_cos)
        print(self.d_sin)
        
    def __call__( self ):
        print(self.d_cos[0,0], self.dM1_cos[0,0], self.k[0] )
        cos_out = self.d_cos*self.k[:,None]-self.dM1_cos
        sin_out = self.d_sin*self.k[:,None]-self.dM1_sin
        self.dM1_cos, self.dM1_sin = self.d_cos, self.d_sin
        self.d_cos, self.d_sin = cos_out, sin_out
        print( self.d_cos[0,0], self.dM1_cos[0,0] )
        return cos_out, sin_out
    
    def dump( self, path=None):
        if path is None : return None
        return np.stack( (self.i.init_dM1.real, self.i.init_dM1.imag, self.i.init_d.real, self.i.init_d.imag), axis=-1 )


class dosc_fixed18(nco_fixed18):
    def __init__( self, fc_Hz, fs_Hz, para=4 ):
        self.i = dosc( fc_Hz, fs_Hz, para )
        self.shape = self.i.shape

        self.k = np.array( self.i.k*2**16, dtype=np.int64 )
        self.dM1_cos = np.array(self.i.init_dM1.real*2**16, dtype=np.int64 )
        self.dM1_sin = np.array(self.i.init_dM1.imag*2**16, dtype=np.int64 )
        self.d_cos   = np.array(self.i.init_d.real*2**16, dtype=np.int64 )
        self.d_sin   = np.array(self.i.init_d.imag*2**16, dtype=np.int64 )

    def __call__( self ):
        print(self.d_cos[0,0], self.dM1_cos[0,0], self.k[0] )
        cos_out = self.normalize(((self.d_cos*self.k[:,None])>>16)-self.dM1_cos)
        sin_out = self.normalize(((self.d_sin*self.k[:,None])>>16)-self.dM1_sin)
        self.dM1_cos, self.dM1_sin = self.d_cos, self.d_sin
        self.d_cos, self.d_sin = cos_out, sin_out
        print( self.d_cos[0,0], self.dM1_cos[0,0] )
        return cos_out, sin_out

    def normalize( self, val ): # Simulate 18bit signed fixed point numbers
        valmod = val % (1<<18)
        return np.where( valmod<(1<<17), valmod, valmod-(1<<18) )

    def dumpcossin(self, path, modulename ):
        k = np.array( self.i.k*2**16, dtype=np.int64 )%(2**18)
        dM1_cos = np.array( self.i.init_dM1.real*2**16, dtype=np.int64 )%(2**18)
        dM1_sin = np.array( self.i.init_dM1.imag*2**16, dtype=np.int64 )%(2**18)
        d_cos   = np.array( self.i.init_d.real*2**16, dtype=np.int64 )%(2**18)
        d_sin   = np.array( self.i.init_d.imag*2**16, dtype=np.int64 )%(2**18)
        self.rom_data = np.stack( (((dM1_sin<<18)|dM1_cos),((d_sin<<18)|d_cos)), axis=-1 )
        self.rom_data[:,0,0] = k
        print(self.rom_data.shape)
        genverilog.simple_rom_write( path, modulename, self.rom_data.ravel(), dbit=36, abit=10, mode='hex', fill=0 )


def nco_int( fc_Hz, fs_Hz=fs_Hz, outsize=128, dbits=18, modulename='nco_rom' ):
    dscale = (2**(dbits-1)-1)
    nco_init_tbli = np.zeros( (len(fc_Hz), 4), dtype=np.int64)
    for fi in range(len(fc_Hz)):
        deltarad = 2.0*np.pi*fc_Hz[fi]/fs_Hz
        nco_init_tbli[fi,:] = (np.cos(deltarad*2)*dscale, np.sin(deltarad*2)*dscale,
                                np.cos(deltarad*1)*dscale,   np.sin(deltarad*1)*dscale)
    converted_positive = np.where( nco_init_tbli<0, (2**dbits)+nco_init_tbli, nco_init_tbli ) 
    genverilog.rom_write( f'./{modulename}.v', modulename, converted_positive.ravel(), dbit=18, abit=11, mode='hex' )
    out = np.zeros((len(fc_Hz), outsize, 4), dtype=np.float64 )
    for fi in range(len(fc_Hz)):
        cosd, sind = nco_init_tbli[fi,0], nco_init_tbli[fi,1]
        cos0, sin0 = dscale, 0
        cos1, sin1 = nco_init_tbli[fi,2], nco_init_tbli[fi,3]
        out[fi, 0, :] = [cos0/dscale, sin0/dscale, cos1/dscale, sin1/dscale]
        for di in range(1, outsize):
            cos0, sin0 = (cos0*cosd-sin0*sind)>>(dbits-1), (sin0*cosd+cos0*sind)>>(dbits-1)
            cos1, sin1 = (cos1*cosd-sin1*sind)>>(dbits-1), (sin1*cosd+cos1*sind)>>(dbits-1)
            out[fi,di,:] = [cos0/dscale, sin0/dscale, cos1/dscale, sin1/dscale]
    return out

def plot_nco( data, fs_Hz=fs_Hz, filename='./nco_float.png' ):
    plotsize = min( 13, data.shape[0] )
    fig, axs = plt.subplots( plotsize, 1, sharex='all', figsize=(16,9) )
    time_s0 = 2.0*np.arange(data.shape[1])/fs_Hz
    time_s1 = 2.0*np.arange(0.5,data.shape[1]+0.5)/fs_Hz
    for fi in range(plotsize):
        axs[fi].plot( time_s0, data[fi,:,0], "-r" )
        axs[fi].plot( time_s0, data[fi,:,1], '-g' )
        axs[fi].plot( time_s1, data[fi,:,2], '--b' )
        axs[fi].plot( time_s1, data[fi,:,3], '--k' )
    plt.savefig( filename )
    plt.show()

def equivalent_bit_positive( value, bits ):
    """
    bits 幅の符号付き整数の配列を、ビットパターンが同じbits幅の符号なし整数の配列に変換します
    """
    np.where( value < 0, (2**bits)-value, value )

A4_Hz=440.0
MIDINO_A4=69
def MIDINO_Hz( midino ):
    return (A4_Hz*pow(2.0,((midino-MIDINO_A4)/12.0)))

def main1():
    #print( fc_test_Hz )
    #plot_nco( nco_float( fc_Hz ) )

    #plot_nco( nco_int( fc_test_Hz ) )
    #fc_Hz = (MIDINO_Hz(60),MIDINO_Hz(61),MIDINO_Hz(62))
    fc_Hz =  np.flip(np.concatenate((np.array([10]),np.linspace(10,2390,479))))
    #fc_Hz = (600, 1200, 1800, 2400)
    plot_nco( nco_int( fc_Hz, outsize=20 ) )


def main2():
    c = nco_complex( fc_Hz=(10, 500, 1000, 1200, 2390), fs_Hz=3000000.0/512.0 )
    c.plot( 100 )

def main3():
    c = nco_float( fc_Hz=(10, 500, 1000, 1200, 2390), fs_Hz=3000000.0/512.0 )
    c.plot( 100 )

def main4():
    c = nco_fixed18( fc_Hz=(10, 500, 1000, 1200, 2390), fs_Hz=3000000.0/512.0 )
    c.plot( 100 )
    c.dumpcossin( 'nco_4ch_fix18_test.v', 'nco_4ch_fix18_test' )
    c.plot( 100 )




def main2_osc( ):
    c = dosc_complex( fc_Hz=(10, 500, 1000, 1200, 2390), fs_Hz=3000000.0/512.0 )
    c.plot( 100 )

def main3_osc( ):
    c = dosc_float( fc_Hz=(10, 500, 1000, 1200, 2390), fs_Hz=3000000.0/512.0 )
    c.plot( 100 )
def main4_osc( ):
    c = dosc_fixed18( fc_Hz=(10, 500, 1000, 1200, 2390), fs_Hz=3000000.0/512.0 )
    c.plot( 100 )



def main4_dosc():
    fc_Hz =  np.flip(np.concatenate((np.array([10]),np.linspace(10,2390,479))))
    c = dosc_fixed18( fc_Hz=fc_Hz, fs_Hz=3000000/512.0, para=2 )
    c.dumpcossin( 'src/python/dosc_rom_2ch_fc2400_fs5859.v', 'dosc_rom_2ch_fc2400_fs5859' )

def main():
    fc_Hz =  np.flip(np.concatenate((np.array([10]),np.linspace(10,2390,479))))
    f = nco_float( fc_Hz=fc_Hz, fs_Hz=3000000/512.0 )
    f.plot(100)
    c = nco_fixed18( fc_Hz=fc_Hz, fs_Hz=3000000/512.0 )
    c.plot(100)
    c.dumpcossin( 'src/python/nco_rom_4ch_fc2400_fs5859.v', 'nco_rom_4ch_fc2400_fs5859' )
    c.plot(100)

    fc_Hz =  np.flip(np.concatenate((np.array([10]),np.linspace(10,2390,479))))
    c = nco_fixed18( fc_Hz=fc_Hz, fs_Hz=3000000/256.0 )
    c.dumpcossin( 'src/python/nco_rom_4ch_fc2400_fs11718.v', 'nco_rom_4ch_fc2400_fs11718' )
    
    fc_Hz =  np.flip(np.concatenate((np.array([20]),np.linspace(20,2390*2,479))))
    c = nco_fixed18( fc_Hz=fc_Hz, fs_Hz=3000000/256.0 )
    c.dumpcossin( 'src/python/nco_rom_4ch_fc4800_fs11718.v', 'nco_rom_4ch_fc4800_fs11718' )

    fc_Hz = np.flip(2.0**(np.arange(-30-240,480-30-240)/60)*442.0)
    c = nco_fixed18( fc_Hz=fc_Hz, fs_Hz=3000000/256.0 )
    c.dumpcossin( 'src/python/nco_rom_4ch_log4943_fs11718.v', 'nco_rom_4ch_log4943_fs11718' )

if __name__ == "__main__":
    main()
    #main4_dosc()