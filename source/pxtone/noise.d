﻿module pxtone.noise;

// '12/03/29

import pxtone.pxtn;

import pxtone.descriptor;

import pxtone.pulse.noisebuilder;
import pxtone.pulse.noise;
import pxtone.pulse.pcm;
import pxtone.error;
import core.stdc.stdint;
import core.stdc.stdlib;

struct pxtoneNoise {
	void *_bldr ;
	int32_t  _ch_num = 2;
	int32_t  _sps = 44100;
	int32_t  _bps = 16;

	~this()
	{
		SAFE_DELETE(_bldr);
	}

	bool init()
	{
		pxtnPulse_NoiseBuilder* bldr = allocate!pxtnPulse_NoiseBuilder();
		if( !bldr.Init() ){ free( cast(void*)bldr ); return false; }
		_bldr = cast(void*)bldr;
		return true;
	}

	bool quality_set( int32_t ch_num, int32_t sps, int32_t bps )
	{
		switch( ch_num )
		{
		case 1: case 2: break;
		default: return false;
		}

		switch( sps )
		{
		case 48000: case 44100: case 22050: case 11025: break;
		default: return false;
		}

		switch( bps )
		{
		case 8: case 16: break;
		default: return false;
		}

		_ch_num = ch_num;
		_bps    = bps   ;
		_sps    = sps   ;

		return false;
	}

	void quality_get( int32_t *p_ch_num, int32_t *p_sps, int32_t *p_bps ) const
	{
		if( p_ch_num ) *p_ch_num = _ch_num;
		if( p_sps    ) *p_sps    = _sps   ;
		if( p_bps    ) *p_bps    = _bps   ;
	}


	bool generate( pxtnDescriptor *p_doc, void **pp_buf, int32_t *p_size ) const
	{
		bool                   b_ret  = false;
		pxtnPulse_NoiseBuilder *bldr  = cast(pxtnPulse_NoiseBuilder*)_bldr;
		pxtnPulse_Noise        *noise = allocate!pxtnPulse_Noise();
		pxtnPulse_PCM          *pcm   = null;

		if( noise.read( p_doc ) != pxtnERR.pxtnOK                     ) goto End;
		pcm = bldr.BuildNoise( noise, _ch_num, _sps, _bps );
		if( !( pcm ) ) goto End;

		*p_size = pcm.get_buf_size();
		*pp_buf = pcm.Devolve_SamplingBuffer();

		b_ret = true;
	End:
		SAFE_DELETE(noise);
		SAFE_DELETE(pcm);

		return b_ret;
	}
}