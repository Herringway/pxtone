module pxtone.delay;

import pxtone.pxtn;

import pxtone.descriptor;
import pxtone.error;
import pxtone.max;
import pxtone.mem;

import core.stdc.stdint;
import core.stdc.stdlib;
import core.stdc.string;

enum DELAYUNIT
{
	DELAYUNIT_Beat = 0,
	DELAYUNIT_Meas    ,
	DELAYUNIT_Second  ,
	DELAYUNIT_num     ,
};


// (12byte) =================
struct _DELAYSTRUCT
{
	uint16_t unit ;
	uint16_t group;
	float    rate ;
	float    freq ;
}

struct pxtnDelay
{
private:
	bool      _b_played = true;
	DELAYUNIT _unit = DELAYUNIT.DELAYUNIT_Beat;
	int32_t   _group = 0;
	float     _rate = 33.0;
	float     _freq = 3.0f;

	int32_t   _smp_num = 0;
	int32_t   _offset = 0;
	int32_t*[ pxtnMAX_CHANNEL ]  _bufs = null;
	int32_t   _rate_s32 = 0;

public :

	~this()
	{
		Tone_Release();
	}

	DELAYUNIT get_unit ()const { return _unit ; }
	int32_t   get_group()const { return _group; }
	float     get_rate ()const { return _rate ; }
	float     get_freq ()const { return _freq ; }

	void      Set( DELAYUNIT unit, float freq, float rate, int32_t group )
	{
		_unit  = unit ;
		_group = group;
		_rate  = rate ;
		_freq  = freq ;
	}

	bool get_played()const{ return _b_played; }
	void set_played( bool b ){ _b_played = b; }
	bool switch_played(){ _b_played = _b_played ? false : true; return _b_played; }



	void Tone_Release()
	{
		for( int32_t i = 0; i < pxtnMAX_CHANNEL; i ++ ) pxtnMem_free( cast(void**)&_bufs[ i ] );
		_smp_num = 0;
	}

	pxtnERR Tone_Ready( int32_t beat_num, float beat_tempo, int32_t sps )
	{
		Tone_Release();

		pxtnERR res = pxtnERR.pxtnERR_VOID;

		if( _freq && _rate )
		{
			_offset   = 0;
			_rate_s32 = cast(int32_t)_rate; // /100;

			switch( _unit )
			{
			case DELAYUNIT.DELAYUNIT_Beat  : _smp_num = cast(int32_t)( sps * 60            / beat_tempo / _freq ); break;
			case DELAYUNIT.DELAYUNIT_Meas  : _smp_num = cast(int32_t)( sps * 60 * beat_num / beat_tempo / _freq ); break;
			case DELAYUNIT.DELAYUNIT_Second: _smp_num = cast(int32_t)( sps                              / _freq ); break;
			default: break;
			}

			for( int32_t c = 0; c < pxtnMAX_CHANNEL; c++ )
			{
				if( !pxtnMem_zero_alloc( cast(void**)&_bufs[ c ], _smp_num * int32_t.sizeof ) ){ res = pxtnERR.pxtnERR_memory; goto term; }
			}
		}

		res = pxtnERR.pxtnOK;
	term:

		if( res != pxtnERR.pxtnOK ) Tone_Release();

		return res;
	}

	void Tone_Supple( int32_t ch, int32_t *group_smps )
	{
		if( !_smp_num ) return;
		int32_t a = _bufs[ ch ][ _offset ] * _rate_s32/ 100;
		if( _b_played ) group_smps[ _group ] += a;
		_bufs[ ch ][ _offset ] =  group_smps[ _group ];
	}

	void Tone_Increment()
	{
		if( !_smp_num ) return;
		if( ++_offset >= _smp_num ) _offset = 0;
	}

	void  Tone_Clear()
	{
		if( !_smp_num ) return;
		int32_t def = 0; // ..
		for( int32_t i = 0; i < pxtnMAX_CHANNEL; i ++ ) memset( _bufs[ i ], def, _smp_num * int32_t.sizeof );
	}




	bool Write( pxtnDescriptor *p_doc ) const
	{
		_DELAYSTRUCT    dela;
		int32_t            size;

		memset( &dela, 0,  _DELAYSTRUCT.sizeof );
		dela.unit  = cast(uint16_t)_unit ;
		dela.group = cast(uint16_t)_group;
		dela.rate  = _rate;
		dela.freq  = _freq;

		// dela ----------
		size =  _DELAYSTRUCT.sizeof;
		if( !p_doc.w_asfile( &size, int32_t.sizeof, 1 ) ) return false;
		if( !p_doc.w_asfile( &dela, size,            1 ) ) return false;

		return true;
	}

	pxtnERR Read( pxtnDescriptor *p_doc )
	{
		_DELAYSTRUCT dela = {0};
		int32_t      size =  0 ;

		if( !p_doc.r( &size, 4,                    1 ) ) return pxtnERR.pxtnERR_desc_r     ;
		if( !p_doc.r( &dela, _DELAYSTRUCT.sizeof, 1 ) ) return pxtnERR.pxtnERR_desc_r     ;
		if( dela.unit >= DELAYUNIT.DELAYUNIT_num                  ) return pxtnERR.pxtnERR_fmt_unknown;

		_unit  = cast(DELAYUNIT)dela.unit;
		_freq  = dela.freq ;
		_rate  = dela.rate ;
		_group = dela.group;

		if( _group >= pxtnMAX_TUNEGROUPNUM ) _group = 0;

		return pxtnERR.pxtnOK;
	}
}