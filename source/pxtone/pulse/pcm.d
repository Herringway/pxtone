﻿module pxtone.pulse.pcm;

import pxtone.pxtn;

import pxtone.error;
import pxtone.descriptor;
import pxtone.mem;

import core.stdc.stdint;
import core.stdc.stdlib;
import core.stdc.string;

struct WAVEFORMATCHUNK
{
	uint16_t formatID;     // PCM:0x0001
	uint16_t ch;           //
	uint32_t sps;          //
	uint32_t byte_per_sec; // byte per sec.
	uint16_t block_size;   //
	uint16_t bps;          // bit per sample.
	uint16_t ext;          // no use for pcm.
}

struct pxtnPulse_PCM
{
private:
	int32_t _ch      ;
	int32_t _sps     ;
	int32_t _bps     ;
	int32_t _smp_head; // no use. 0
	int32_t _smp_body;
	int32_t _smp_tail; // no use. 0
	uint8_t  *_p_smp  ;

	// stereo / mono
	bool _Convert_ChannelNum( int32_t new_ch )
	{
		ubyte* p_work = null;
		int32_t           sample_size;
		int32_t           work_size;
		int32_t           a,b;
		int32_t           temp1;
		int32_t           temp2;

		sample_size = ( _smp_head + _smp_body + _smp_tail ) * _ch * _bps / 8;

		if( _p_smp == null   ) return false;
		if( _ch    == new_ch ) return true ;


		// mono to stereo --------
		if( new_ch == 2 )
		{
			work_size = sample_size * 2;
			p_work     = cast(ubyte *)malloc( work_size );
			if( !p_work ) return false;

			switch( _bps )
			{
			case  8:
				b = 0;
				for( a = 0; a < sample_size; a++ )
				{
					p_work[b  ] = _p_smp[a];
					p_work[b+1] = _p_smp[a];
					b += 2;
				}
				break;
			case 16:
				b = 0;
				for( a = 0; a < sample_size; a += 2 )
				{
					p_work[b  ] = _p_smp[a  ];
					p_work[b+1] = _p_smp[a+1];
					p_work[b+2] = _p_smp[a  ];
					p_work[b+3] = _p_smp[a+1];
					b += 4;
				}
				break;
			default: break;
			}

		}
		// stereo to mono --------
		else
		{
			work_size = sample_size / 2;
			p_work     = cast(ubyte *)malloc( work_size );
			if( !p_work ) return false;

			switch( _bps )
			{
			case  8:
				b = 0;
				for( a = 0; a < sample_size; a+= 2 )
				{
					temp1       = cast(int32_t)_p_smp[a] + cast(int32_t)_p_smp[a+1];
					p_work[b  ] = cast(uint8_t)( temp1 / 2 );
					b++;
				}
				break;
			case 16:
				b = 0;
				for( a = 0; a < sample_size; a += 4 )
				{
					temp1                = *(cast(int16_t *)(&_p_smp[a  ]));
					temp2                = *(cast(int16_t *)(&_p_smp[a+2]));
					*cast(int16_t *)(&p_work[b]) =   cast(int16_t)( ( temp1 + temp2 ) / 2 );
					b += 2;
				}
				break;
			default: break;
			}
		}

		// release once.
		free( _p_smp );
		_p_smp = null;

		_p_smp = cast(uint8_t*)malloc( work_size );
		if( !( _p_smp ) ){ free( p_work ); return false; }
		memcpy( _p_smp, p_work, work_size );
		free( p_work );

		// update param.
		_ch = new_ch;

		return true;
	}

	// change bps
	bool _Convert_BitPerSample( int32_t new_bps )
	{
		ubyte* p_work;
		int32_t           sample_size;
		int32_t           work_size;
		int32_t           a,b;
		int32_t           temp1;

		if( !_p_smp         ) return false;
		if( _bps == new_bps ) return true ;

		sample_size = ( _smp_head + _smp_body + _smp_tail ) * _ch * _bps / 8;

		switch( new_bps )
		{
		// 16 to 8 --------
		case  8:
			work_size = sample_size / 2;
			p_work     = cast(uint8_t*)malloc( work_size );
			if( !p_work ) return false;
			b = 0;
			for( a = 0; a < sample_size; a += 2 )
			{
				temp1 = *(cast(int16_t*)(&_p_smp[a]));
				temp1 = (temp1/0x100) + 128;
				p_work[b] = cast(uint8_t)temp1;
				b++;
			}
			break;
		//  8 to 16 --------
		case 16:
			work_size = sample_size * 2;
			p_work     = cast(uint8_t*)malloc( work_size );
			if( !p_work ) return false;
			b = 0;
			for( a = 0; a < sample_size; a++ )
			{
				temp1 = _p_smp[a];
				temp1 = ( temp1 - 128 ) * 0x100;
				*(cast(int16_t *)(&p_work[b])) = cast(int16_t)temp1;
				b += 2;
			}
			break;

		default: return false;
		}

		// release once.
		free( _p_smp );
		_p_smp = null;

		_p_smp = cast(uint8_t*)malloc( work_size );
		if( !( _p_smp ) ){ free( p_work ); return false; }
		memcpy( _p_smp, p_work, work_size );
		free( p_work );

		// update param.
		_bps = new_bps;

		return true;
	}
	// sps
	bool _Convert_SamplePerSecond( int32_t new_sps )
	{
		bool     b_ret = false;
		int32_t  sample_num;
		int32_t  work_size;

		int32_t  head_size, body_size, tail_size;

		uint8_t  *p1byte_data;
		uint16_t *p2byte_data;
		uint32_t *p4byte_data;

		uint8_t  *p1byte_work = null;
		uint16_t *p2byte_work = null;
		uint32_t *p4byte_work = null;


		int32_t a, b;

		if( !_p_smp         ) return false;
		if( _sps == new_sps ) return true ;

		head_size = _smp_head * _ch * _bps / 8;
		body_size = _smp_body * _ch * _bps / 8;
		tail_size = _smp_tail * _ch * _bps / 8;

		head_size = cast(int32_t)( ( cast(double)head_size * cast(double)new_sps + cast(double)(_sps) - 1 ) / _sps );
		body_size = cast(int32_t)( ( cast(double)body_size * cast(double)new_sps + cast(double)(_sps) - 1 ) / _sps );
		tail_size = cast(int32_t)( ( cast(double)tail_size * cast(double)new_sps + cast(double)(_sps) - 1 ) / _sps );

		work_size = head_size + body_size + tail_size;

		// stereo 16bit ========
		if(     _ch == 2 && _bps == 16 )
		{
			_smp_head   = head_size  / 4;
			_smp_body   = body_size  / 4;
			_smp_tail   = tail_size  / 4;
			sample_num  = work_size  / 4;
			work_size   = sample_num * 4;
			p4byte_data = cast(uint32_t *)_p_smp;
			if( !pxtnMem_zero_alloc( cast(void **)&p4byte_work, work_size ) ) goto End;
			for( a = 0; a < sample_num; a++ )
			{
				b = cast(int32_t)( cast(double)a * cast(double)(_sps) / cast(double)new_sps );
				p4byte_work[a] = p4byte_data[b];
			}
		}
		// mono 8bit ========
		else if( _ch == 1 && _bps ==  8 )
		{
			_smp_head = head_size  / 1;
			_smp_body = body_size  / 1;
			_smp_tail = tail_size  / 1;
			sample_num      = work_size  / 1;
			work_size       = sample_num * 1;
			p1byte_data     = cast(uint8_t*)_p_smp;
			if( !pxtnMem_zero_alloc( cast(void **)&p1byte_work, work_size ) ) goto End;
			for( a = 0; a < sample_num; a++ )
			{
				b = cast(int32_t)( cast(double)a * cast(double)(_sps) / cast(double)(new_sps) );
				p1byte_work[a] = p1byte_data[b];
			}
		}
		else
		// mono 16bit / stereo 8bit ========
		{
			_smp_head = head_size  / 2;
			_smp_body = body_size  / 2;
			_smp_tail = tail_size  / 2;
			sample_num      = work_size  / 2;
			work_size       = sample_num * 2;
			p2byte_data     = cast(uint16_t*)_p_smp;
			if( !pxtnMem_zero_alloc( cast(void**)&p2byte_work, work_size ) ) goto End;
			for( a = 0; a < sample_num; a++ )
			{
				b = cast(int32_t)( cast(double)a * cast(double)(_sps) / cast(double)new_sps );
				p2byte_work[a] = p2byte_data[b];
			}
		}

		// release once.
		pxtnMem_free( cast(void **)&_p_smp );
		if( !pxtnMem_zero_alloc( cast(void **)&_p_smp, work_size ) ) goto End;

		if(      p4byte_work ) memcpy( _p_smp, p4byte_work, work_size );
		else if( p2byte_work ) memcpy( _p_smp, p2byte_work, work_size );
		else if( p1byte_work ) memcpy( _p_smp, p1byte_work, work_size );
		else goto End;

		// update.
		_sps = new_sps;

		b_ret = true;
	End:

		if( !b_ret )
		{
			pxtnMem_free( cast(void **)&_p_smp );
			_smp_head = 0;
			_smp_body = 0;
			_smp_tail = 0;
		}

		pxtnMem_free( cast(void **)&p2byte_work  );
		pxtnMem_free( cast(void **)&p1byte_work  );
		pxtnMem_free( cast(void **)&p4byte_work  );

		return b_ret;
	}

public:
	~this()
	{
		Release();
	}

	pxtnERR Create( int32_t ch, int32_t sps, int32_t bps, int32_t sample_num )
	{
		Release();

		if( bps != 8 && bps != 16 ) return pxtnERR.pxtnERR_pcm_unknown;

		int32_t size = 0;

		_p_smp    = null;
		_ch       = ch  ;
		_sps      = sps ;
		_bps      = bps ;
		_smp_head =    0;
		_smp_body = sample_num;
		_smp_tail =    0;

		// bit / sample is 8 or 16
		size = _smp_body * _bps * _ch / 8;

		_p_smp = cast(uint8_t*)malloc( size );
		if( !( _p_smp ) ) return pxtnERR.pxtnERR_memory;

		if( _bps == 8 ) memset( _p_smp, 128, size );
		else            memset( _p_smp,   0, size );

		return pxtnERR.pxtnOK;
	}

	void Release()
	{
		if( _p_smp ) free( _p_smp ); _p_smp = null;
		_ch       =    0;
		_sps      =    0;
		_bps      =    0;
		_smp_head =    0;
		_smp_body =    0;
		_smp_tail =    0;
	}

	pxtnERR read( pxtnDescriptor* doc )
	{
		pxtnERR        res       = pxtnERR.pxtnERR_VOID;
		char[ 16 ]            buf =  0;
		uint32_t        size      =   0  ;
		WAVEFORMATCHUNK format    = { 0 };

		_p_smp = null;

		// 'RIFFxxxxWAVEfmt '
		if( !doc.r( buf.ptr, char.sizeof, 16 ) ){ res = pxtnERR.pxtnERR_desc_r; goto term; }

		if( buf[ 0] != 'R' || buf[ 1] != 'I' || buf[ 2] != 'F' || buf[ 3] != 'F' ||
			buf[ 8] != 'W' || buf[ 9] != 'A' || buf[10] != 'V' || buf[11] != 'E' ||
			buf[12] != 'f' || buf[13] != 'm' || buf[14] != 't' || buf[15] != ' ' )
		{
			res = pxtnERR.pxtnERR_pcm_unknown; goto term;
		}

		// read format.
		if( !doc.r( &size  , uint32_t.sizeof, 1 ) ){ res = pxtnERR.pxtnERR_desc_r     ; goto term; }
		if( !doc.r( &format,               18, 1 ) ){ res = pxtnERR.pxtnERR_desc_r     ; goto term; }

		if( format.formatID != 0x0001               ){ res = pxtnERR.pxtnERR_pcm_unknown; goto term; }
		if( format.ch  != 1 && format.ch  !=  2     ){ res = pxtnERR.pxtnERR_pcm_unknown; goto term; }
		if( format.bps != 8 && format.bps != 16     ){ res = pxtnERR.pxtnERR_pcm_unknown; goto term; }

		// find 'data'
		if( !doc.seek( pxtnSEEK.pxtnSEEK_set, 12 ) ){ res = pxtnERR.pxtnERR_desc_r; goto term; } // skip 'RIFFxxxxWAVE'

		while( 1 )
		{
			if( !doc.r( buf.ptr  , char.sizeof, 4 )      ){ res = pxtnERR.pxtnERR_desc_r; goto term; }
			if( !doc.r( &size, uint32_t.sizeof, 1 ) ){ res = pxtnERR.pxtnERR_desc_r; goto term; }
			if( buf[0] == 'd' && buf[1] == 'a' && buf[2] == 't' && buf[3] == 'a' ) break;
			if( !doc.seek( pxtnSEEK.pxtnSEEK_cur, size )       ){ res = pxtnERR.pxtnERR_desc_r; goto term; }
		}

		res = Create( format.ch, format.sps, format.bps, size * 8 / format.bps / format.ch );
		if( res !=pxtnERR. pxtnOK ) goto term;

		if( !doc.r( _p_smp, uint8_t.sizeof, size )   ){ res = pxtnERR.pxtnERR_desc_r; goto term; }

		res = pxtnERR.pxtnOK;
	term:

		if( res != pxtnERR.pxtnOK && _p_smp ){ free( _p_smp ); _p_smp = null; }
		return res;
	}

	bool write  ( pxtnDescriptor* doc, const char* pstrLIST ) const
	{
		if( !_p_smp ) return false;

		WAVEFORMATCHUNK format;
		bool            b_ret = false;
		uint32_t   riff_size;
		uint32_t   fact_size; // num sample.
		uint32_t   list_size; // num list text.
		uint32_t   isft_size;
		uint32_t   sample_size;

		bool bText;

		char[4] tag_RIFF = ['R','I','F','F'];
		char[4] tag_WAVE = ['W','A','V','E'];
		char[8] tag_fmt_ = ['f','m','t',' ', 0x12,0,0,0];
		char[8] tag_fact = ['f','a','c','t', 0x04,0,0,0];
		char[4] tag_data = ['d','a','t','a'];
		char[4] tag_LIST = ['L','I','S','T'];
		char[8] tag_INFO = ['I','N','F','O','I','S','F','T'];


		if( pstrLIST && strlen( pstrLIST ) ) bText = true ;
		else                                 bText = false;

		sample_size         = ( _smp_head + _smp_body + _smp_tail ) * _ch * _bps / 8;

		format.formatID     = 0x0001;// PCM
		format.ch           = cast(uint16_t) _ch;
		format.sps          = cast(uint32_t) _sps;
		format.bps          = cast(uint16_t) _bps;
		format.byte_per_sec = cast(uint32_t)(_sps * _bps * _ch / 8);
		format.block_size   = cast(uint16_t)(             _bps * _ch / 8);
		format.ext          = 0;

		fact_size = ( _smp_head + _smp_body + _smp_tail );
		riff_size  = sample_size;
		riff_size +=  4;// 'WAVE'
		riff_size += 26;// 'fmt '
		riff_size += 12;// 'fact'
		riff_size +=  8;// 'data'

		if( bText )
		{
			isft_size = cast(uint32_t)strlen( pstrLIST );
			list_size = 4 + 4 + 4 + isft_size; // "INFO" + "ISFT" + size + ver_Text;
			riff_size +=  8 + list_size;// 'LIST'
		}
		else
		{
			isft_size = 0;
			list_size = 0;
		}

		// open file..

		if( !doc.w_asfile( tag_RIFF.ptr,     char.sizeof, 4 ) ) goto End;
		if( !doc.w_asfile( &riff_size,   uint32_t.sizeof, 1 ) ) goto End;
		if( !doc.w_asfile( tag_WAVE.ptr,     char.sizeof, 4 ) ) goto End;
		if( !doc.w_asfile( tag_fmt_.ptr,     char.sizeof, 8 ) ) goto End;
		if( !doc.w_asfile( &format,                    18, 1 ) ) goto End;

		if( bText )
		{
			if( !doc.w_asfile( tag_LIST.ptr,     char.sizeof, 4 ) ) goto End;
			if( !doc.w_asfile( &list_size,   uint32_t.sizeof, 1 ) ) goto End;
			if( !doc.w_asfile( tag_INFO.ptr,     char.sizeof, 8 ) ) goto End;
			if( !doc.w_asfile( &isft_size,   uint32_t.sizeof, 1 ) ) goto End;
			if( !doc.w_asfile( pstrLIST,     char.sizeof, isft_size ) ) goto End;
		}

		if( !doc.w_asfile( tag_fact.ptr,     char.sizeof, 8 ) ) goto End;
		if( !doc.w_asfile( &fact_size,   uint32_t.sizeof, 1 ) ) goto End;
		if( !doc.w_asfile( tag_data.ptr,     char.sizeof, 4 ) ) goto End;
		if( !doc.w_asfile( &sample_size, int32_t.sizeof, 1 ) ) goto End;
		if( !doc.w_asfile( _p_smp, char.sizeof, sample_size ) ) goto End;

		b_ret = true;

	End:

		return b_ret;
	}


	// convert..
	bool Convert( int32_t new_ch, int32_t new_sps, int32_t new_bps )
	{
		if( !_Convert_ChannelNum     ( new_ch  ) ) return false;
		if( !_Convert_BitPerSample   ( new_bps ) ) return false;
		if( !_Convert_SamplePerSecond( new_sps ) ) return false;

		return true;
	}
	bool Convert_Volume( float v )
	{
		if( !_p_smp ) return false;

		int32_t sample_num = ( _smp_head + _smp_body + _smp_tail ) * _ch;

		switch( _bps )
		{
		case  8:
			{
				uint8_t *p8 = cast(uint8_t*)_p_smp;
				for( int32_t i = 0; i < sample_num; i++ )
				{
					*p8 = cast(uint8_t)( ( ( cast(float)(*p8) - 128 ) * v ) + 128 );
					p8++;
				}
				break;
			}
		case 16:
			{
				short *p16 = cast(int16_t *)_p_smp;
				for( int32_t i = 0; i < sample_num; i++ )
				{
					*p16 = cast(int16_t)( cast(float)*p16 * v );
					p16++;
				}
				break;
			}
		default:
			return false;
		}
		return true;
	}
	pxtnERR Copy( pxtnPulse_PCM *p_dst ) const
	{
		pxtnERR res = pxtnERR.pxtnERR_VOID;
		if( !_p_smp ){ p_dst.Release(); return pxtnERR.pxtnOK; }
		res = p_dst.Create( _ch, _sps, _bps, _smp_body ); if( res != pxtnERR.pxtnOK ) return res;
		memcpy( p_dst._p_smp, _p_smp, ( _smp_head + _smp_body + _smp_tail ) * _ch * _bps / 8 );
		return pxtnERR.pxtnOK;
	}
	bool Copy_( pxtnPulse_PCM *p_dst, int32_t start, int32_t end ) const
	{
		int32_t size, offset;

		if( _smp_head || _smp_tail     ) return false;
		if( !_p_smp ){ p_dst.Release(); return true; }

		size   = ( end - start ) * _ch * _bps / 8;
		offset =         start   * _ch * _bps / 8;

		if( p_dst.Create( _ch, _sps, _bps, end - start ) != pxtnERR.pxtnOK ) return false;

		memcpy( p_dst._p_smp, &_p_smp[ offset ], size );

		return true;
	}

	void *Devolve_SamplingBuffer()
	{
		void *p = _p_smp;
		_p_smp = null;
		return p;
	}

	float get_sec   () const
	{
		return cast(float)(_smp_body+_smp_head+_smp_tail) / cast(float)_sps;
	}

	int32_t     get_ch            () const{ return _ch      ; }
	int32_t     get_bps           () const{ return _bps     ; }
	int32_t     get_sps           () const{ return _sps     ; }
	int32_t     get_smp_body      () const{ return _smp_body; }
	int32_t     get_smp_head      () const{ return _smp_head; }
	int32_t     get_smp_tail      () const{ return _smp_tail; }

	int32_t get_buf_size() const
	{
		return ( _smp_head + _smp_body + _smp_tail ) * _ch * _bps / 8;
	}

	const(void) *get_p_buf         () const{ return _p_smp   ; }
	void       *get_p_buf_variable() const{ return cast(void*)_p_smp   ; }

}