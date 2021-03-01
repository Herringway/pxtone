﻿module pxtone.pulse.frequency;

import pxtone.pxtn;

import core.stdc.stdint;
import core.stdc.stdlib;

enum _OCTAVE_NUM = 16;   // octave num.
enum _KEY_PER_OCTAVE = 12;   // key per octave
enum _FREQUENCY_PER_KEY = 0x10; // sample per key

enum _BASIC_FREQUENCY_INDEX = ((_OCTAVE_NUM/2) * _KEY_PER_OCTAVE * _FREQUENCY_PER_KEY );
enum _TABLE_SIZE = ( _OCTAVE_NUM    * _KEY_PER_OCTAVE * _FREQUENCY_PER_KEY );


struct pxtnPulse_Frequency {
	float* _freq_table;
	double _GetDivideOctaveRate( int32_t  divi )
	{
		double parameter = 1.0;
		double work;
		double result;
		double add;
		int32_t  i, j, k;

		// double is 17keta.
		for( i = 0; i < 17; i++ )
		{
			// make add.
	 		add = 1;
			for( j = 0; j < i; j++ ) add = add * 0.1;

			// check 0 .. 9 
			for( j = 0; j < 10; j++ )
			{
				work = parameter + add * j;

				// divide
				result = 1.0;
				for( k = 0; k < divi; k++ )
				{
					result *= work;
					if( result >= 2.0 ) break;
				}

				// under '2'
				if( k != divi ) break;
			}
			// before '2'
			parameter += add * ( j - 1 );
		}

		return parameter;
	}

	~this()
	{
		if( _freq_table ) free( _freq_table ); _freq_table = null;
	}

	bool Init()
	{
		bool b_ret = false;
		double[ _OCTAVE_NUM ] oct_table =
		[
			0.00390625, //0  -8
			0.0078125,  //1  -7
			0.015625,   //2  -6
			0.03125,    //3  -5
			0.0625,     //4  -4
			0.125,      //5  -3
			0.25,       //6  -2
			0.5,        //7  -1
			1,          //8
			2,          //9   1
			4,          //a   2
			8,          //b   3
			16,         //c   4
			32,         //d   5
			64,         //e   6
			128,        //f   7
		];

		int32_t    key ;
		int32_t    f   ;
		double oct_x24;
		double work;

		_freq_table = cast(float*)malloc( float.sizeof * _TABLE_SIZE );
		if( !( _freq_table ) ) goto End;

		oct_x24 = _GetDivideOctaveRate( _KEY_PER_OCTAVE * _FREQUENCY_PER_KEY );

		for( f = 0; f < _OCTAVE_NUM * (_KEY_PER_OCTAVE * _FREQUENCY_PER_KEY); f++ )
		{
			work = oct_table[   f /  (_KEY_PER_OCTAVE * _FREQUENCY_PER_KEY) ];
			for( key = 0; key < f %  (_KEY_PER_OCTAVE * _FREQUENCY_PER_KEY); key++ )
			{
				work *= oct_x24;
			}
			_freq_table[ f ] = cast(float) work;
		}
		b_ret = true;
	End:
		return b_ret;
	}

	float Get( int32_t key ) const
	{
		int32_t  i;

		i = (key + 0x6000) * _FREQUENCY_PER_KEY / 0x100;
		if     ( i <            0 ) i = 0;
		else if( i >= _TABLE_SIZE ) i = _TABLE_SIZE -1;
		return _freq_table[ i ];
	}

	float Get2( int32_t key )
	{
		int32_t  i = key >> 4;
		if     ( i <            0 ) i = 0;
		else if( i >= _TABLE_SIZE ) i = _TABLE_SIZE - 1;
		return _freq_table[ i ];
	}

	const(float)* GetDirect( int32_t  *p_size )
	{
		*p_size = _TABLE_SIZE;
		return _freq_table;
	}
}