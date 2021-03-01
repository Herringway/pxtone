﻿module pxtone.woice;
// '12/03/03 pxtnWoice.

import pxtone.pxtn;

import pxtone.descriptor;
import pxtone.error;
import pxtone.evelist;
import pxtone.mem;
import pxtone.pulse.noise;
import pxtone.pulse.noisebuilder;
import pxtone.pulse.oscillator;
import pxtone.pulse.pcm;
import pxtone.pulse.oggv;
import pxtone.woiceptv;
import core.stdc.stdint;

import core.stdc.stdlib;
import core.stdc.string;

enum pxtnMAX_TUNEWOICENAME = 16; // fixture.

enum pxtnMAX_UNITCONTROLVOICE = 2; // max-woice per unit

enum pxtnBUFSIZE_TIMEPAN = 0x40;
enum pxtnBITPERSAMPLE = 16;

enum PTV_VOICEFLAG_WAVELOOP = 0x00000001;
enum PTV_VOICEFLAG_SMOOTH = 0x00000002;
enum PTV_VOICEFLAG_BEATFIT = 0x00000004;
enum PTV_VOICEFLAG_UNCOVERED = 0xfffffff8;

enum PTV_DATAFLAG_WAVE = 0x00000001;
enum PTV_DATAFLAG_ENVELOPE = 0x00000002;
enum PTV_DATAFLAG_UNCOVERED = 0xfffffffc;

enum pxtnWOICETYPE
{
	pxtnWOICE_None = 0,
	pxtnWOICE_PCM ,
	pxtnWOICE_PTV ,
	pxtnWOICE_PTN ,
	pxtnWOICE_OGGV,
};

enum pxtnVOICETYPE
{
	pxtnVOICE_Coodinate = 0,
	pxtnVOICE_Overtone ,
	pxtnVOICE_Noise    ,
	pxtnVOICE_Sampling ,
	pxtnVOICE_OggVorbis,
};

struct pxtnVOICEINSTANCE
{
	int32_t  smp_head_w ;
	int32_t  smp_body_w ;
	int32_t  smp_tail_w ;
	uint8_t* p_smp_w    ;

	uint8_t* p_env      ;
	int32_t  env_size   ;
	int32_t  env_release;
}


struct pxtnVOICEENVELOPE
{
	int    fps     ;
	int    head_num;
	int    body_num;
	int    tail_num;
	pxtnPOINT* points  ;
}


struct pxtnVOICEWAVE
{
	int    num    ;
	int    reso   ; // COODINATERESOLUTION
	pxtnPOINT *points;
}


struct pxtnVOICEUNIT
{
	int           basic_key  ;
	int           volume     ;
	int           pan        ;
	float             tuning     ;
	uint32_t          voice_flags;
	uint32_t          data_flags ;

	pxtnVOICETYPE     type       ;
	pxtnPulse_PCM     *p_pcm     ;
	pxtnPulse_Noise   *p_ptn     ;
version(pxINCLUDE_OGGVORBIS) {
	pxtnPulse_Oggv    *p_oggv    ;
}

	pxtnVOICEWAVE     wave       ;
	pxtnVOICEENVELOPE envelope   ;
}


struct pxtnVOICETONE
{
	double  smp_pos    ;
	float   offset_freq;
	int32_t env_volume ;
	int32_t life_count ;
	int32_t on_count   ;

	int32_t smp_count  ;
	int32_t env_start  ;
	int32_t env_pos    ;
	int32_t env_release_clock;

	int32_t smooth_volume;
}



static void _Voice_Release( pxtnVOICEUNIT* p_vc, pxtnVOICEINSTANCE* p_vi )
{
	if( p_vc )
	{
		SAFE_DELETE( p_vc.p_pcm  );
		SAFE_DELETE( p_vc.p_ptn  );
version(pxINCLUDE_OGGVORBIS) {
		SAFE_DELETE( p_vc.p_oggv );
}
		pxtnMem_free( cast(void**)&p_vc.envelope.points ); memset( &p_vc.envelope, 0, pxtnVOICEENVELOPE.sizeof );
		pxtnMem_free( cast(void**)&p_vc.wave.points     ); memset( &p_vc.wave    , 0, pxtnVOICEWAVE.sizeof );
	}
	if( p_vi )
	{
		pxtnMem_free( cast(void**)&p_vi.p_env           );
		pxtnMem_free( cast(void**)&p_vi.p_smp_w         );
		memset( p_vi, 0, pxtnVOICEINSTANCE.sizeof );
	}
}


void _UpdateWavePTV( pxtnVOICEUNIT* p_vc, pxtnVOICEINSTANCE* p_vi, int32_t  ch, int32_t  sps, int32_t  bps )
{
	double  work, osc;
	int32_t long_;
	int32_t[ 2 ] pan_volume = [64, 64];
	bool    b_ovt;

	pxtnPulse_Oscillator osci;

	if( ch == 2 )
	{
		if( p_vc.pan > 64 ) pan_volume[ 0 ] = ( 128 - p_vc.pan );
		if( p_vc.pan < 64 ) pan_volume[ 1 ] = (       p_vc.pan );
	}

	osci.ReadyGetSample( p_vc.wave.points, p_vc.wave.num, p_vc.volume, p_vi.smp_body_w, p_vc.wave.reso );

	if( p_vc.type == pxtnVOICETYPE.pxtnVOICE_Overtone ) b_ovt = true ;
	else                                   b_ovt = false;

	//  8bit
	if( bps ==  8 )
	{
		uint8_t* p = cast(uint8_t*)p_vi.p_smp_w;
		for( int32_t s = 0; s < p_vi.smp_body_w; s++ )
		{
			if( b_ovt ) osc = osci.GetOneSample_Overtone ( s );
			else        osc = osci.GetOneSample_Coodinate( s );
			for( int32_t c = 0; c < ch; c++ )
			{
				work = osc * pan_volume[ c ] / 64;
				if( work >  1.0 ) work =  1.0;
				if( work < -1.0 ) work = -1.0;
				long_  = cast(int32_t )( work * 127 );
				p[ s * ch + c ] = cast(uint8_t)(long_ + 128);
			}
		}

	// 16bit
	}
	else
	{
		int16_t* p = cast(int16_t*)p_vi.p_smp_w;
		for( int32_t s = 0; s < p_vi.smp_body_w; s++ )
		{
			if( b_ovt ) osc = osci.GetOneSample_Overtone ( s );
			else        osc = osci.GetOneSample_Coodinate( s );
			for( int32_t c = 0; c < ch; c++ )
			{
				work = osc * pan_volume[ c ] / 64;
				if( work >  1.0 ) work =  1.0;
				if( work < -1.0 ) work = -1.0;
				long_  = cast(int32_t )( work * 32767 );
				p[ s * ch + c ] = cast(int16_t)long_;
			}
		}
	}
}



// 24byte =================
struct _MATERIALSTRUCT_PCM
{
	uint16_t x3x_unit_no;
	uint16_t basic_key  ;
	uint32_t voice_flags;
	uint16_t ch         ;
	uint16_t bps        ;
	uint32_t sps        ;
	float    tuning     ;
	uint32_t data_size  ;
}


/////////////
// matePTN
/////////////

// 16byte =================
struct _MATERIALSTRUCT_PTN
{
	uint16_t x3x_unit_no;
	uint16_t basic_key  ;
	uint32_t voice_flags;
	float    tuning     ;
	int32_t  rrr        ; // 0: -v.0.9.2.3
	                      // 1:  v.0.9.2.4-
}


/////////////////
// matePTV
/////////////////

// 24byte =================
struct _MATERIALSTRUCT_PTV
{
	uint16_t x3x_unit_no;
	uint16_t rrr        ;
	float    x3x_tuning ;
	int32_t  size       ;
}



//////////////////////
// mateOGGV
//////////////////////

// 16byte =================
struct _MATERIALSTRUCT_OGGV
{
	uint16_t xxx        ; //ch;
	uint16_t basic_key  ;
	uint32_t voice_flags;
	float    tuning     ;
}


////////////////////////
// publics..
////////////////////////


struct pxtnWoice
{
private:
	int32_t            _voice_num;

	char[ pxtnMAX_TUNEWOICENAME + 1 ]               _name_buf;
	int32_t            _name_size    ;

	pxtnWOICETYPE      _type = pxtnWOICETYPE.pxtnWOICE_None;
	pxtnVOICEUNIT*     _voices       ;
	pxtnVOICEINSTANCE* _voinsts      ;

	float              _x3x_tuning   ;
	int            _x3x_basic_key; // tuning old-fmt when key-event

public :

	~this()
	{
		Voice_Release();
	}

	int32_t       get_voice_num    () const{ return _voice_num    ; }
	float         get_x3x_tuning   () const{ return _x3x_tuning   ; }
	int       get_x3x_basic_key() const{ return _x3x_basic_key; }
	pxtnWOICETYPE get_type         () const{ return _type         ; }

	const(pxtnVOICEUNIT)*get_voice( int32_t idx ) const
	{
		if( idx < 0 || idx >= _voice_num ) return null;
		return &_voices[ idx ];
	}
	pxtnVOICEUNIT *get_voice_variable( int32_t idx )
	{
		if( idx < 0 || idx >= _voice_num ) return null;
		return &_voices[ idx ];
	}


	const(pxtnVOICEINSTANCE) *get_instance( int32_t idx ) const
	{
		if( idx < 0 || idx >= _voice_num ) return null;
		return &_voinsts[ idx ];
	}

	bool set_name_buf( const(char) *name, int32_t buf_size )
	{
		if( !name || buf_size < 0 || buf_size > pxtnMAX_TUNEWOICENAME ) return false;
		memset( _name_buf.ptr, 0, _name_buf.sizeof );
		if( buf_size ) memcpy( _name_buf.ptr, name, buf_size );
		_name_size = buf_size;
		return true;
	}

	const(char)* get_name_buf( int32_t* p_buf_size ) const return
	{
		if( p_buf_size ) *p_buf_size = _name_size;
		return _name_buf.ptr;
	}

	bool is_name_buf () const
	{
		if( _name_size > 0 ) return true;
		return false;
	}


	bool Voice_Allocate( int32_t voice_num )
	{
		bool b_ret = false;

		Voice_Release();

		if( !pxtnMem_zero_alloc( cast(void**)&_voices , pxtnVOICEUNIT.sizeof * voice_num ) ) goto End;
		if( !pxtnMem_zero_alloc( cast(void**)&_voinsts, pxtnVOICEINSTANCE.sizeof * voice_num ) ) goto End;
		_voice_num = voice_num;

		for( int32_t i = 0; i < voice_num; i++ )
		{
			pxtnVOICEUNIT *p_vc = &_voices[ i ];
			p_vc.basic_key   = EVENTDEFAULT_BASICKEY;
			p_vc.volume      =  128;
			p_vc.pan         =   64;
			p_vc.tuning     =  1.0f;
			p_vc.voice_flags = PTV_VOICEFLAG_SMOOTH;
			p_vc.data_flags  = PTV_DATAFLAG_WAVE   ;
			p_vc.p_pcm       = allocate!pxtnPulse_PCM  ();
			p_vc.p_ptn       = allocate!pxtnPulse_Noise();
	version(pxINCLUDE_OGGVORBIS) {
			p_vc.p_oggv      = allocate!pxtnPulse_Oggv ();
	}
			memset( &p_vc.envelope, 0, pxtnVOICEENVELOPE.sizeof );
		}

		b_ret = true;
	End:

		if( !b_ret ) Voice_Release();

		return b_ret;
	}

	void Voice_Release ()
	{
		for( int32_t v = 0; v < _voice_num; v++ ) _Voice_Release( &_voices[ v ], &_voinsts[ v ] );
		pxtnMem_free( cast(void**)&_voices  );
		pxtnMem_free( cast(void**)&_voinsts );
		_voice_num = 0;
	}

	bool Copy( pxtnWoice *p_dst ) const
	{
		bool           b_ret = false;
		int32_t        v, size, num;
		const(pxtnVOICEUNIT)* p_vc1 = null ;
		pxtnVOICEUNIT* p_vc2 = null ;

		if( !p_dst.Voice_Allocate( _voice_num ) ) goto End;

		p_dst._type = _type;

		memcpy( p_dst._name_buf.ptr, _name_buf.ptr, _name_buf.sizeof );
		p_dst._name_size = _name_size;

		for( v = 0; v < _voice_num; v++ )
		{
			p_vc1 = &       _voices[ v ];
			p_vc2 = &p_dst._voices[ v ];

			p_vc2.tuning            = p_vc1.tuning     ;
			p_vc2.data_flags        = p_vc1.data_flags ;
			p_vc2.basic_key         = p_vc1.basic_key  ;
			p_vc2.pan               = p_vc1.pan        ;
			p_vc2.type              = p_vc1.type       ;
			p_vc2.voice_flags       = p_vc1.voice_flags;
			p_vc2.volume            = p_vc1.volume     ;

			// envelope
			p_vc2.envelope.body_num = p_vc1.envelope.body_num;
			p_vc2.envelope.fps      = p_vc1.envelope.fps     ;
			p_vc2.envelope.head_num = p_vc1.envelope.head_num;
			p_vc2.envelope.tail_num = p_vc1.envelope.tail_num;
			num  = p_vc2.envelope.head_num + p_vc2.envelope.body_num + p_vc2.envelope.tail_num;
			size = pxtnPOINT.sizeof * num;
			if( !pxtnMem_zero_alloc( cast(void **)&p_vc2.envelope.points, size ) ) goto End;
			memcpy(                            p_vc2.envelope.points, p_vc1.envelope.points, size );

			// wave
			p_vc2.wave.num          = p_vc1.wave.num ;
			p_vc2.wave.reso         = p_vc1.wave.reso;
			size = pxtnPOINT.sizeof * p_vc2.wave.num ;
			if( !pxtnMem_zero_alloc( cast(void **)&p_vc2.wave.points, size ) ) goto End;
			memcpy(                            p_vc2.wave.points, p_vc1.wave.points, size );

			if(  p_vc1.p_pcm .Copy( p_vc2.p_pcm  ) != pxtnERR.pxtnOK ) goto End;
			if( !p_vc1.p_ptn .Copy( p_vc2.p_ptn  )           ) goto End;
	version(pxINCLUDE_OGGVORBIS) {
			if( !p_vc1.p_oggv.Copy( p_vc2.p_oggv )           ) goto End;
	}
		}

		b_ret = true;
	End:
		if( !b_ret ) p_dst.Voice_Release();

		return b_ret;
	}

	void Slim()
	{
		for( int32_t i = _voice_num - 1; i >= 0; i-- )
		{
			bool b_remove = false;

			if( !_voices[ i ].volume ) b_remove = true;

			if( _voices[ i ].type == pxtnVOICETYPE.pxtnVOICE_Coodinate && _voices[ i ].wave.num <= 1 ) b_remove = true;

			if( b_remove )
			{
				_Voice_Release( &_voices[ i ], &_voinsts[ i ] );
				_voice_num--;
				for( int32_t j = i; j < _voice_num; j++ ) _voices[ j ] = _voices[ j + 1 ];
				memset( &_voices[ _voice_num ], 0, pxtnVOICEUNIT.sizeof );
			}
		}
	}

	pxtnERR read( pxtnDescriptor* desc, pxtnWOICETYPE type )
	{
		pxtnERR res = pxtnERR.pxtnERR_VOID;

		switch( type )
		{
		// PCM
		case pxtnWOICETYPE.pxtnWOICE_PCM:
			{
				pxtnVOICEUNIT *p_vc; if( !Voice_Allocate( 1 ) ) goto term; p_vc = &_voices[ 0 ]; p_vc.type = pxtnVOICETYPE.pxtnVOICE_Sampling;
				res = p_vc.p_pcm.read( desc ); if( res != pxtnERR.pxtnOK ) goto term;
				// if under 0.005 sec, set LOOP.
				if(p_vc.p_pcm.get_sec() < 0.005f ) p_vc.voice_flags |=  PTV_VOICEFLAG_WAVELOOP;
				else                                 p_vc.voice_flags &= ~PTV_VOICEFLAG_WAVELOOP;
				_type      = pxtnWOICETYPE.pxtnWOICE_PCM;
			}
			break;

		// PTV
		case pxtnWOICETYPE.pxtnWOICE_PTV:
			{
				res = PTV_Read( desc ); if( res != pxtnERR.pxtnOK ) goto term;
			}
			break;

		// PTN
		case pxtnWOICETYPE.pxtnWOICE_PTN:
			if( !Voice_Allocate( 1 ) ){ res = pxtnERR.pxtnERR_memory; goto term; }
			{
				pxtnVOICEUNIT *p_vc = &_voices[ 0 ]; p_vc.type = pxtnVOICETYPE.pxtnVOICE_Noise;
				res = p_vc.p_ptn.read( desc ); if( res != pxtnERR.pxtnOK ) goto term;
				_type = pxtnWOICETYPE.pxtnWOICE_PTN;
			}
			break;

		// OGGV
		case pxtnWOICETYPE.pxtnWOICE_OGGV:
	version(pxINCLUDE_OGGVORBIS) {
			if( !Voice_Allocate( 1 ) ){ res = pxtnERR.pxtnERR_memory; goto term; }
			{
				pxtnVOICEUNIT *p_vc;  p_vc = &_voices[ 0 ]; p_vc.type = pxtnVOICETYPE.pxtnVOICE_OggVorbis;
				res = p_vc.p_oggv.ogg_read( desc ); if( res != pxtnERR.pxtnOK ) goto term;
				_type      = pxtnWOICETYPE.pxtnWOICE_OGGV;
			}
			break;
	} else {
			res = pxtnERR.pxtnERR_ogg_no_supported; goto term;
	}

		default: goto term;
		}

		res = pxtnERR.pxtnOK;
	term:

		return res;
	}
	bool PTV_Write( pxtnDescriptor *p_doc, int32_t *p_total ) const
	{
		bool           b_ret = false;
		const(pxtnVOICEUNIT)* p_vc  = null ;
		uint       work  =     0;
		int        v     =     0;
		int        total =     0;

		if( !p_doc.w_asfile  ( _code     ,                1, 8 ) ) goto End;
		if( !p_doc.w_asfile  ( &_version , uint32_t.sizeof, 1 ) ) goto End;
		if( !p_doc.w_asfile  ( &total    , int32_t.sizeof, 1 ) ) goto End;

		work = 0;

		// p_ptv. (5)
		if( !p_doc.v_w_asfile( work      , &total ) ) goto End; // basic_key (no use)
		if( !p_doc.v_w_asfile( work      , &total ) ) goto End;
		if( !p_doc.v_w_asfile( work      , &total ) ) goto End;
		if( !p_doc.v_w_asfile( _voice_num, &total ) ) goto End;

		for( v = 0; v < _voice_num; v++ )
		{
			// p_ptvv. (9)
			p_vc = &_voices[ v ];
			if( !p_vc ) goto End;

			if( !p_doc.v_w_asfile( p_vc.basic_key  , &total ) ) goto End;
			if( !p_doc.v_w_asfile( p_vc.volume     , &total ) ) goto End;
			if( !p_doc.v_w_asfile( p_vc.pan        , &total ) ) goto End;
			memcpy( &work, &p_vc.tuning, 4.sizeof );
			if( !p_doc.v_w_asfile( work             , &total ) ) goto End;
			if( !p_doc.v_w_asfile( p_vc.voice_flags, &total ) ) goto End;
			if( !p_doc.v_w_asfile( p_vc.data_flags , &total ) ) goto End;

			if( p_vc.data_flags & PTV_DATAFLAG_WAVE     && !_Write_Wave(     p_doc, p_vc, &total ) ) goto End;
			if( p_vc.data_flags & PTV_DATAFLAG_ENVELOPE && !_Write_Envelope( p_doc, p_vc, &total ) ) goto End;
		}

		// total size
		if( !p_doc.seek( pxtnSEEK.pxtnSEEK_cur, -(total + 4)     ) ) goto End;
		if( !p_doc.w_asfile( &total, int32_t.sizeof, 1 ) ) goto End;
		if( !p_doc.seek( pxtnSEEK.pxtnSEEK_cur,  (total    )     ) ) goto End;

		if( p_total ) *p_total = 16 + total;
		b_ret  = true;
	End:

		return b_ret;
	}
	pxtnERR PTV_Read( pxtnDescriptor *p_doc )
	{
		pxtnERR        res       = pxtnERR.pxtnERR_VOID;
		pxtnVOICEUNIT* p_vc      = null ;
		uint8_t[ 8 ]        code =  0;
		int        version_   =     0;
		int        work1     =     0;
		int        work2     =     0;
		int        total     =     0;
		int        num       =     0;

		if( !p_doc.r( code.ptr    ,               1, 8 ) ){ res = pxtnERR.pxtnERR_desc_r  ; goto term; }
		if( !p_doc.r( &version_, int32_t.sizeof, 1 ) ){ res = pxtnERR.pxtnERR_desc_r  ; goto term; }
		if( memcmp( code.ptr, _code, 8 )                  ){ res = pxtnERR.pxtnERR_inv_code; goto term; }
		if( !p_doc.r( &total  , int32_t.sizeof, 1 ) ){ res = pxtnERR.pxtnERR_desc_r  ; goto term; }
		if( version_ > _version                        ){ res = pxtnERR.pxtnERR_fmt_new ; goto term; }

		// p_ptv. (5)
		if( !p_doc.v_r( &_x3x_basic_key ) ){ res = pxtnERR.pxtnERR_desc_r     ; goto term; }
		if( !p_doc.v_r( &work1          ) ){ res = pxtnERR.pxtnERR_desc_r     ; goto term; }
		if( !p_doc.v_r( &work2          ) ){ res = pxtnERR.pxtnERR_desc_r     ; goto term; }
		if( work1 || work2                 ){ res = pxtnERR.pxtnERR_fmt_unknown; goto term; }
		if( !p_doc.v_r    ( &num )        ){ res = pxtnERR.pxtnERR_desc_r     ; goto term; }
		if( !Voice_Allocate(  num )        ){ res = pxtnERR.pxtnERR_memory     ; goto term; }

		for( int32_t v = 0; v < _voice_num; v++ )
		{
			// p_ptvv. (8)
			p_vc = &_voices[ v ];
			if( !p_vc                                       ){ res = pxtnERR.pxtnERR_FATAL ; goto term; }
			if( !p_doc.v_r( &p_vc.basic_key )             ){ res = pxtnERR.pxtnERR_desc_r; goto term; }
			if( !p_doc.v_r( &p_vc.volume    )             ){ res = pxtnERR.pxtnERR_desc_r; goto term; }
			if( !p_doc.v_r( &p_vc.pan       )             ){ res = pxtnERR.pxtnERR_desc_r; goto term; }
			if( !p_doc.v_r( &work1           )             ){ res = pxtnERR.pxtnERR_desc_r; goto term; }
			memcpy( &p_vc.tuning, &work1,  4.sizeof     );
			if( !p_doc.v_r( cast(int*)&p_vc.voice_flags )     ){ res = pxtnERR.pxtnERR_desc_r; goto term; }
			if( !p_doc.v_r( cast(int*)&p_vc.data_flags  )     ){ res = pxtnERR.pxtnERR_desc_r; goto term; }

			// no support.
			if( p_vc.voice_flags & PTV_VOICEFLAG_UNCOVERED ){ res = pxtnERR.pxtnERR_fmt_unknown; goto term; }
			if( p_vc.data_flags  & PTV_DATAFLAG_UNCOVERED  ){ res = pxtnERR.pxtnERR_fmt_unknown; goto term; }
			if( p_vc.data_flags  & PTV_DATAFLAG_WAVE       ){ res = _Read_Wave(     p_doc, p_vc ); if( res != pxtnERR.pxtnOK ) goto term; }
			if( p_vc.data_flags  & PTV_DATAFLAG_ENVELOPE   ){ res = _Read_Envelope( p_doc, p_vc ); if( res != pxtnERR.pxtnOK ) goto term; }
		}
		_type = pxtnWOICETYPE.pxtnWOICE_PTV;

		res = pxtnERR.pxtnOK;
	term:

		return res;
	}

	bool io_matePCM_w( pxtnDescriptor *p_doc ) const
	{
		const pxtnPulse_PCM* p_pcm =  _voices[ 0 ].p_pcm;
		const(pxtnVOICEUNIT)*       p_vc  = &_voices[ 0 ];
		_MATERIALSTRUCT_PCM  pcm;

		memset( &pcm, 0,  _MATERIALSTRUCT_PCM.sizeof );

		pcm.sps         = cast(uint32_t)p_pcm.get_sps     ();
		pcm.bps         = cast(uint16_t)p_pcm.get_bps     ();
		pcm.ch          = cast(uint16_t)p_pcm.get_ch      ();
		pcm.data_size   = cast(uint32_t)p_pcm.get_buf_size();
		pcm.x3x_unit_no = cast(uint16_t)0;
		pcm.tuning      =           p_vc.tuning     ;
		pcm.voice_flags =           p_vc.voice_flags;
		pcm.basic_key   = cast(uint16_t)p_vc.basic_key  ;

		uint32_t size =  _MATERIALSTRUCT_PCM.sizeof + pcm.data_size;
		if( !p_doc.w_asfile( &size, uint32_t.sizeof, 1 ) ) return false;
		if( !p_doc.w_asfile( &pcm , _MATERIALSTRUCT_PCM.sizeof, 1 ) ) return false;
		if( !p_doc.w_asfile( p_pcm.get_p_buf(), 1, pcm.data_size  ) ) return false;

		return true;
	}

	pxtnERR io_matePCM_r( pxtnDescriptor *p_doc )
	{
		pxtnERR             res  = pxtnERR.pxtnERR_VOID;
		_MATERIALSTRUCT_PCM pcm  = {0};
		int32_t             size =  0 ;

		if( !p_doc.r( &size, 4,                            1 ) ) return pxtnERR.pxtnERR_desc_r;
		if( !p_doc.r( &pcm,  _MATERIALSTRUCT_PCM.sizeof, 1 ) ) return pxtnERR.pxtnERR_desc_r;

		if( (cast(int32_t)pcm.voice_flags) & PTV_VOICEFLAG_UNCOVERED )return pxtnERR.pxtnERR_fmt_unknown;

		if( !Voice_Allocate( 1 ) ){ res = pxtnERR.pxtnERR_memory; goto term; }

		{
			pxtnVOICEUNIT* p_vc = &_voices[ 0 ];

			p_vc.type = pxtnVOICETYPE.pxtnVOICE_Sampling;

			res = p_vc.p_pcm.Create( pcm.ch, pcm.sps, pcm.bps, pcm.data_size / ( pcm.bps / 8 * pcm.ch ) );
			if( res != pxtnERR.pxtnOK ) goto term;
			if( !p_doc.r( p_vc.p_pcm.get_p_buf_variable(), 1, pcm.data_size ) ){ res = pxtnERR.pxtnERR_desc_r; goto term; }
			_type      = pxtnWOICETYPE.pxtnWOICE_PCM;

			p_vc.voice_flags = pcm.voice_flags;
			p_vc.basic_key   = pcm.basic_key  ;
			p_vc.tuning      = pcm.tuning     ;
			_x3x_basic_key    = pcm.basic_key  ;
			_x3x_tuning       =               0;
		}
		res = pxtnERR.pxtnOK;
	term:

		if( res != pxtnERR.pxtnOK ) Voice_Release();
		return res;
	}

	bool io_matePTN_w( pxtnDescriptor *p_doc ) const
	{
		_MATERIALSTRUCT_PTN ptn ;
		const(pxtnVOICEUNIT)*      p_vc;
		int32_t                 size = 0;

		// ptv -------------------------
		memset( &ptn, 0,  _MATERIALSTRUCT_PTN.sizeof );
		ptn.x3x_unit_no   = cast(uint16_t)0;

		p_vc = &_voices[ 0 ];
		ptn.tuning      =           p_vc.tuning     ;
		ptn.voice_flags =           p_vc.voice_flags;
		ptn.basic_key   = cast(uint16_t)p_vc.basic_key  ;
		ptn.rrr         =                           1;

		// pre
		if( !p_doc.w_asfile( &size, int32_t.sizeof,             1 ) ) return false;
		if( !p_doc.w_asfile( &ptn,  _MATERIALSTRUCT_PTN.sizeof, 1 ) ) return false;
		size += _MATERIALSTRUCT_PTN.sizeof;
		if( !p_vc.p_ptn.write( p_doc, &size )                       ) return false;
		if( !p_doc.seek( pxtnSEEK.pxtnSEEK_cur, -size - int32_t.sizeof )     ) return false;
		if( !p_doc.w_asfile( &size, int32_t.sizeof,             1 ) ) return false;
		if( !p_doc.seek( pxtnSEEK.pxtnSEEK_cur, size )                        ) return false;

		return true;
	}


	pxtnERR io_matePTN_r( pxtnDescriptor *p_doc )
	{
		pxtnERR             res  = pxtnERR.pxtnERR_VOID; 
		_MATERIALSTRUCT_PTN ptn  = {0};
		int32_t             size =  0 ;

		if( !p_doc.r( &size, int32_t.sizeof,               1 ) ) return pxtnERR.pxtnERR_desc_r;
		if( !p_doc.r( &ptn,   _MATERIALSTRUCT_PTN.sizeof, 1 ) ) return pxtnERR.pxtnERR_desc_r;

		if     ( ptn.rrr > 1 ) return pxtnERR.pxtnERR_fmt_unknown;
		else if( ptn.rrr < 0 ) return pxtnERR.pxtnERR_fmt_unknown;

		if( !Voice_Allocate( 1 ) ) return pxtnERR.pxtnERR_memory;

		{
			pxtnVOICEUNIT *p_vc = &_voices[ 0 ];

			p_vc.type = pxtnVOICETYPE.pxtnVOICE_Noise;
			res = p_vc.p_ptn.read( p_doc ); if( res != pxtnERR.pxtnOK ) goto term;
			_type = pxtnWOICETYPE.pxtnWOICE_PTN;
			p_vc.voice_flags  = ptn.voice_flags;
			p_vc.basic_key    = ptn.basic_key  ;
			p_vc.tuning       = ptn.tuning     ;
		}

		_x3x_basic_key = ptn.basic_key;
		_x3x_tuning    =             0;

		res = pxtnERR.pxtnOK;
	term:
		if( res != pxtnERR.pxtnOK ) Voice_Release();
		return res;
	}
	bool io_matePTV_w( pxtnDescriptor *p_doc ) const
	{
		_MATERIALSTRUCT_PTV ptv;
		int32_t                 head_size = _MATERIALSTRUCT_PTV.sizeof + int32_t.sizeof;
		int32_t                 size = 0;

		// ptv -------------------------
		memset( &ptv, 0,  _MATERIALSTRUCT_PTV.sizeof );
		ptv.x3x_unit_no = cast(uint16_t)0;
		ptv.x3x_tuning  =           0;//1.0f;//p_w.tuning;
		ptv.size        =           0;

		// pre write
		if( !p_doc.w_asfile( &size, int32_t.sizeof,             1 ) ) return false;
		if( !p_doc.w_asfile( &ptv,  _MATERIALSTRUCT_PTV.sizeof, 1 ) ) return false;
		if( !PTV_Write( p_doc, &ptv.size )       ) return false;

		if( !p_doc.seek( pxtnSEEK.pxtnSEEK_cur, -( ptv.size + head_size ) ) ) return false;

		size = ptv.size +  _MATERIALSTRUCT_PTV.sizeof;
		if( !p_doc.w_asfile( &size, int32_t.sizeof,             1 ) ) return false;
		if( !p_doc.w_asfile( &ptv,  _MATERIALSTRUCT_PTV.sizeof, 1 ) ) return false;

		if( !p_doc.seek( pxtnSEEK.pxtnSEEK_cur, ptv.size )                    ) return false;

		return true;
	}

	pxtnERR io_matePTV_r( pxtnDescriptor *p_doc )
	{
		pxtnERR             res  = pxtnERR.pxtnERR_VOID;
		_MATERIALSTRUCT_PTV ptv  = {0};
		int32_t             size =  0 ;

		if( !p_doc.r( &size, int32_t.sizeof,               1 ) ) return pxtnERR.pxtnERR_desc_r;
		if( !p_doc.r( &ptv,   _MATERIALSTRUCT_PTV.sizeof, 1 ) ) return pxtnERR.pxtnERR_desc_r;
		if( ptv.rrr ) return pxtnERR.pxtnERR_fmt_unknown;
		res = PTV_Read( p_doc ); if( res != pxtnERR.pxtnOK ) goto term;

		if( ptv.x3x_tuning != 1.0 ) _x3x_tuning = ptv.x3x_tuning;
		else                        _x3x_tuning =              0;

		res = pxtnERR.pxtnOK;
	term:

		return res;
	}
version(pxINCLUDE_OGGVORBIS) {
	bool io_mateOGGV_w( pxtnDescriptor *p_doc ) const
	{
		if( !_voices ) return false;

		_MATERIALSTRUCT_OGGV mate = {0};
		pxtnVOICEUNIT*       p_vc = &_voices[ 0 ];

		if( !p_vc.p_oggv ) return false;

		int32_t oggv_size = p_vc.p_oggv.GetSize();

		mate.tuning      =           p_vc.tuning     ;
		mate.voice_flags =           p_vc.voice_flags;
		mate.basic_key   = cast(uint16_t)p_vc.basic_key  ;

		uint32_t size =  _MATERIALSTRUCT_OGGV.sizeof + oggv_size;
		if( !p_doc.w_asfile( &size, uint32_t.sizeof            , 1 ) ) return false;
		if( !p_doc.w_asfile( &mate, _MATERIALSTRUCT_OGGV.sizeof, 1 ) ) return false;
		if( !p_vc.p_oggv.pxtn_write( p_doc ) ) return false;

		return true;
	}

	pxtnERR io_mateOGGV_r( pxtnDescriptor *p_doc )
	{
		pxtnERR              res  = pxtnERR.pxtnERR_VOID;
		_MATERIALSTRUCT_OGGV mate = {0};
		int32_t              size =  0 ;

		if( !p_doc.r( &size, 4,                              1 ) ) return pxtnERR.pxtnERR_desc_r;
		if( !p_doc.r( &mate,  _MATERIALSTRUCT_OGGV.sizeof, 1 ) ) return pxtnERR.pxtnERR_desc_r;

		if( (cast(int32_t)mate.voice_flags) & PTV_VOICEFLAG_UNCOVERED ) return pxtnERR.pxtnERR_fmt_unknown;

		if( !Voice_Allocate( 1 ) ) goto End;

		{
			pxtnVOICEUNIT *p_vc = &_voices[ 0 ];
			p_vc.type = pxtnVOICETYPE.pxtnVOICE_OggVorbis;

			if( !p_vc.p_oggv.pxtn_read( p_doc ) ) goto End;

			p_vc.voice_flags  = mate.voice_flags;
			p_vc.basic_key    = mate.basic_key  ;
			p_vc.tuning       = mate.tuning     ;
		}

		_x3x_basic_key = mate.basic_key;
		_x3x_tuning    =              0;
		_type          = pxtnWOICETYPE.pxtnWOICE_OGGV;

		res = pxtnERR.pxtnOK;
	End:
		if( res != pxtnERR.pxtnOK ) Voice_Release();
		return res;
	}
}

	pxtnERR Tone_Ready_sample( const pxtnPulse_NoiseBuilder* ptn_bldr )
	{
		pxtnERR            res   = pxtnERR.pxtnERR_VOID;
		pxtnVOICEINSTANCE* p_vi  = null ;
		pxtnVOICEUNIT*     p_vc  = null ;
		pxtnPulse_PCM      pcm_work;

		int32_t            ch    =     2;
		int32_t            sps   = 44100;
		int32_t            bps   =    16;

		for( int32_t v = 0; v < _voice_num; v++ )
		{
			p_vi = &_voinsts[ v ];
			pxtnMem_free( cast(void **)&p_vi.p_smp_w );
			p_vi.smp_head_w = 0;
			p_vi.smp_body_w = 0;
			p_vi.smp_tail_w = 0;
		}

		for( int32_t v = 0; v < _voice_num; v++ )
		{
			p_vi = &_voinsts[ v ];
			p_vc = &_voices [ v ];

			switch( p_vc.type )
			{
			case pxtnVOICETYPE.pxtnVOICE_OggVorbis:

	version(pxINCLUDE_OGGVORBIS) {
				res = p_vc.p_oggv.Decode( &pcm_work );
				if( res != pxtnERR.pxtnOK ) goto term;
				if( !pcm_work.Convert( ch, sps, bps  ) ) goto term;
				p_vi.smp_head_w = pcm_work.get_smp_head();
				p_vi.smp_body_w = pcm_work.get_smp_body();
				p_vi.smp_tail_w = pcm_work.get_smp_tail();
				p_vi.p_smp_w    = cast(uint8_t*)pcm_work.Devolve_SamplingBuffer();
				break;
	} else {
				res = pxtnERR.pxtnERR_ogg_no_supported; goto term;
	}

			case pxtnVOICETYPE.pxtnVOICE_Sampling:

				res = p_vc.p_pcm.Copy( &pcm_work ); if( res != pxtnERR.pxtnOK ) goto term;
				if( !pcm_work.Convert( ch, sps, bps ) ){ res = pxtnERR.pxtnERR_pcm_convert; goto term; }
				p_vi.smp_head_w = pcm_work.get_smp_head();
				p_vi.smp_body_w = pcm_work.get_smp_body();
				p_vi.smp_tail_w = pcm_work.get_smp_tail();
				p_vi.p_smp_w    = cast(uint8_t*)pcm_work.Devolve_SamplingBuffer();
				break;

			case pxtnVOICETYPE.pxtnVOICE_Overtone :
			case pxtnVOICETYPE.pxtnVOICE_Coodinate:
				{
					p_vi.smp_body_w =  400;
					int32_t size = p_vi.smp_body_w * ch * bps / 8;
					p_vi.p_smp_w = cast(uint8_t*)malloc( size );
					if( !( p_vi.p_smp_w ) ){ res = pxtnERR.pxtnERR_memory; goto term; }
					memset( p_vi.p_smp_w, 0x00, size );
					_UpdateWavePTV( p_vc, p_vi, ch, sps, bps );
					break;
				}

			case pxtnVOICETYPE.pxtnVOICE_Noise:
				{
					pxtnPulse_PCM *p_pcm = null;
					if( !ptn_bldr ){ res = pxtnERR.pxtnERR_ptn_init; goto term; }
					p_pcm = ptn_bldr.BuildNoise( p_vc.p_ptn, ch, sps, bps );
					if( !( p_pcm ) ){ res = pxtnERR.pxtnERR_ptn_build; goto term; }
					p_vi.p_smp_w = cast(uint8_t*)p_pcm.Devolve_SamplingBuffer();
					p_vi.smp_body_w = p_vc.p_ptn.get_smp_num_44k();
					break;
				}
			default: break;
			}
		}

		res = pxtnERR.pxtnOK;
	term:
		if( res != pxtnERR.pxtnOK )
		{
			for( int32_t v = 0; v < _voice_num; v++ )
			{
				p_vi = &_voinsts[ v ];
				pxtnMem_free( cast(void **)&p_vi.p_smp_w );
				p_vi.smp_head_w = 0;
				p_vi.smp_body_w = 0;
				p_vi.smp_tail_w = 0;
			}
		}

		return res;
	}

	pxtnERR Tone_Ready_envelope( int32_t sps )
	{
		pxtnERR    res     = pxtnERR.pxtnERR_VOID;
		int32_t    e       =            0;
		pxtnPOINT* p_point = null        ;

		for( int32_t v = 0; v < _voice_num; v++ )
		{
			pxtnVOICEINSTANCE* p_vi   = &_voinsts[ v ] ;
			pxtnVOICEUNIT*     p_vc   = &_voices [ v ] ;
			pxtnVOICEENVELOPE* p_enve = &p_vc.envelope;
			int32_t            size   =               0;

			pxtnMem_free( cast(void**)&p_vi.p_env );

			if( p_enve.head_num )
			{
				for( e = 0; e < p_enve.head_num; e++ ) size += p_enve.points[ e ].x;
				p_vi.env_size = cast(int32_t)( cast(double)size * sps / p_enve.fps );
				if( !p_vi.env_size ) p_vi.env_size = 1;

				if( !pxtnMem_zero_alloc( cast(void**)&p_vi.p_env, p_vi.env_size                       ) ){ res = pxtnERR.pxtnERR_memory; goto term; }
				if( !pxtnMem_zero_alloc( cast(void**)&p_point    , pxtnPOINT.sizeof * p_enve.head_num ) ){ res = pxtnERR.pxtnERR_memory; goto term; }

				// convert points.
				int32_t  offset   = 0;
				int32_t  head_num = 0;
				for( e = 0; e < p_enve.head_num; e++ )
				{
					if( !e || p_enve.points[ e ].x ||  p_enve.points[ e ].y )
					{
						offset        += cast(int32_t)( cast(double)p_enve.points[ e ].x * sps / p_enve.fps );
						p_point[ e ].x = offset;
						p_point[ e ].y =                p_enve.points[ e ].y;
						head_num++;
					}
				}

				pxtnPOINT start;
				e = start.x = start.y = 0;
				for( int32_t  s = 0; s < p_vi.env_size; s++ )
				{
					while( e < head_num && s >= p_point[ e ].x )
					{
						start.x = p_point[ e ].x;
						start.y = p_point[ e ].y;
						e++;
					}

					if(    e < head_num )
					{
						p_vi.p_env[ s ] = cast(uint8_t)(
													start.y + ( p_point[ e ].y - start.y ) *
													(              s - start.x ) /
													( p_point[ e ].x - start.x ) );
					}
					else
					{
						p_vi.p_env[ s ] = cast(uint8_t)start.y;
					}
				}

				pxtnMem_free( cast(void**)&p_point );
			}

			if( p_enve.tail_num )
			{
				p_vi.env_release = cast(int32_t)( cast(double)p_enve.points[ p_enve.head_num ].x * sps / p_enve.fps );
			}
			else
			{
				p_vi.env_release = 0;
			}
		}

		res = pxtnERR.pxtnOK;
	term:

		pxtnMem_free( cast(void**)&p_point );

		if( res != pxtnERR.pxtnOK ){ for( int32_t v = 0; v < _voice_num; v++ ) pxtnMem_free( cast(void**)&_voinsts[ v ].p_env ); }

		return res;
	}
	pxtnERR Tone_Ready( const pxtnPulse_NoiseBuilder* ptn_bldr, int32_t sps )
	{
		pxtnERR res = pxtnERR.pxtnERR_VOID;
		res = Tone_Ready_sample  ( ptn_bldr ); if( res != pxtnERR.pxtnOK ) return res;
		res = Tone_Ready_envelope( sps      ); if( res != pxtnERR.pxtnOK ) return res;
		return pxtnERR.pxtnOK;
	}
};