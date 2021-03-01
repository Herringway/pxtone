module pxtone.evelist;

import pxtone.pxtn;

import pxtone.descriptor;
import pxtone.error;

import core.stdc.stdint;
import core.stdc.stdlib;
import core.stdc.string;

///////////////////////
// global
///////////////////////

bool Evelist_Kind_IsTail( int32_t kind )
{
	if( kind == EVENTKIND_ON || kind == EVENTKIND_PORTAMENT ) return true;
	return false;
}

enum
{
	EVENTKIND_null  = 0 ,//  0

	EVENTKIND_ON        ,//  1
	EVENTKIND_KEY       ,//  2
	EVENTKIND_PAN_VOLUME,//  3
	EVENTKIND_VELOCITY  ,//  4
	EVENTKIND_VOLUME    ,//  5
	EVENTKIND_PORTAMENT ,//  6
	EVENTKIND_BEATCLOCK ,//  7
	EVENTKIND_BEATTEMPO ,//  8
	EVENTKIND_BEATNUM   ,//  9
	EVENTKIND_REPEAT    ,// 10
	EVENTKIND_LAST      ,// 11
	EVENTKIND_VOICENO   ,// 12
	EVENTKIND_GROUPNO   ,// 13
	EVENTKIND_TUNING    ,// 14
	EVENTKIND_PAN_TIME  ,// 15

	EVENTKIND_NUM       ,// 16
};

enum EVENTDEFAULT_VOLUME = 104;
enum EVENTDEFAULT_VELOCITY = 104;
enum EVENTDEFAULT_PAN_VOLUME = 64;
enum EVENTDEFAULT_PAN_TIME = 64;
enum EVENTDEFAULT_PORTAMENT = 0;
enum EVENTDEFAULT_VOICENO = 0;
enum EVENTDEFAULT_GROUPNO = 0;
enum EVENTDEFAULT_KEY = 0x6000;
enum EVENTDEFAULT_BASICKEY = 0x4500; // 4A(440Hz?)
enum EVENTDEFAULT_TUNING = 1.0f;

enum EVENTDEFAULT_BEATNUM = 4;
enum EVENTDEFAULT_BEATTEMPO = 120;
enum EVENTDEFAULT_BEATCLOCK = 480;

struct EVERECORD
{
	uint8_t    kind    ;
	uint8_t    unit_no ;
	uint8_t    reserve1;
	uint8_t    reserve2;
	int32_t    value   ;
	int32_t    clock   ;
	EVERECORD* prev    ;
	EVERECORD* next    ;
}

static int32_t _DefaultKindValue( uint8_t kind )
{
	switch( kind )
	{
//	case EVENTKIND_ON        : return ;
	case EVENTKIND_KEY       : return EVENTDEFAULT_KEY      ;
	case EVENTKIND_PAN_VOLUME: return EVENTDEFAULT_PAN_VOLUME  ;
	case EVENTKIND_VELOCITY  : return EVENTDEFAULT_VELOCITY ;
	case EVENTKIND_VOLUME    : return EVENTDEFAULT_VOLUME   ;
	case EVENTKIND_PORTAMENT : return EVENTDEFAULT_PORTAMENT;
	case EVENTKIND_BEATCLOCK : return EVENTDEFAULT_BEATCLOCK;
	case EVENTKIND_BEATTEMPO : return EVENTDEFAULT_BEATTEMPO;
	case EVENTKIND_BEATNUM   : return EVENTDEFAULT_BEATNUM  ;
//	case EVENTKIND_REPEAT    : return ;
//	case EVENTKIND_LAST      : return ;
	case EVENTKIND_VOICENO   : return EVENTDEFAULT_VOICENO  ;
	case EVENTKIND_GROUPNO   : return EVENTDEFAULT_GROUPNO  ;
	case EVENTKIND_TUNING    :
		{
			float tuning;
			tuning = EVENTDEFAULT_TUNING;
			return *( cast(int32_t*)&tuning );
		}
	case EVENTKIND_PAN_TIME  : return EVENTDEFAULT_PAN_TIME ;
	default: break;
	}
	return 0;
}
static int32_t _ComparePriority( uint8_t kind1, uint8_t kind2 )
{
	static const int32_t[ EVENTKIND_NUM ] priority_table =
	[
		  0, // EVENTKIND_null  = 0
		 50, // EVENTKIND_ON
		 40, // EVENTKIND_KEY
		 60, // EVENTKIND_PAN_VOLUME
		 70, // EVENTKIND_VELOCITY
		 80, // EVENTKIND_VOLUME
		 30, // EVENTKIND_PORTAMENT
		  0, // EVENTKIND_BEATCLOCK
		  0, // EVENTKIND_BEATTEMPO
		  0, // EVENTKIND_BEATNUM
		  0, // EVENTKIND_REPEAT
		255, // EVENTKIND_LAST
		 10, // EVENTKIND_VOICENO
		 20, // EVENTKIND_GROUPNO
		 90, // EVENTKIND_TUNING
		100, // EVENTKIND_PAN_TIME
	];

	return priority_table[ kind1 ] - priority_table[ kind2 ];
}

// event struct(12byte) =================
struct _x4x_EVENTSTRUCT
{
	uint16_t unit_index;
	uint16_t event_kind;
	uint16_t data_num;        // １イベントのデータ数。現在は 2 ( clock / volume ）
	uint16_t rrr;
	uint32_t  event_num;
}

//--------------------------------

struct pxtnEvelist
{

private:

	int32_t    _eve_allocated_num;
	EVERECORD* _eves     ;
	EVERECORD* _start    ;
	int32_t    _linear   ;

	EVERECORD* _p_x4x_rec;

	void _rec_set( EVERECORD* p_rec, EVERECORD* prev, EVERECORD* next, int32_t clock, uint8_t unit_no, uint8_t kind, int32_t value )
	{
		if( prev ) prev.next = p_rec;
		else       _start     = p_rec;
		if( next ) next.prev = p_rec;

		p_rec.next    = next   ;
		p_rec.prev    = prev   ;
		p_rec.clock   = clock  ;
		p_rec.kind    = kind   ;
		p_rec.unit_no = unit_no;
		p_rec.value   = value  ;
	}
	void _rec_cut( EVERECORD* p_rec )
	{
		if( p_rec.prev ) p_rec.prev.next = p_rec.next;
		else              _start            = p_rec.next;
		if( p_rec.next ) p_rec.next.prev = p_rec.prev;
		p_rec.kind = EVENTKIND_null;
	}

public:

	void Release()
	{
		if( _eves ) free( _eves );
		_eves              = null;
		_start             = null;
		_eve_allocated_num =    0;
	}
	void Clear()
	{
		if( _eves ) memset( _eves, 0, EVERECORD.sizeof * _eve_allocated_num );
		_start   = null;
	}

	~this()
	{
		Release();
	}


	bool Allocate( int32_t max_event_num )
	{
		Release();
		_eves = cast(EVERECORD*)malloc( EVERECORD.sizeof * max_event_num );
		if( !(  _eves ) ) return false;
		memset( _eves, 0,                   EVERECORD.sizeof * max_event_num );
		_eve_allocated_num = max_event_num;
		return true;
	}

	int32_t  get_Num_Max() const
	{
		if( !_eves ) return 0;
		return _eve_allocated_num;
	}

	int32_t  get_Max_Clock() const
	{
		int32_t max_clock = 0;
		int32_t clock;

		for( const(EVERECORD)* p = _start; p; p = p.next )
		{
			if( Evelist_Kind_IsTail( p.kind ) ) clock = p.clock + p.value;
			else                                 clock = p.clock           ;
			if( clock > max_clock ) max_clock = clock;
		}

		return max_clock;

	}

	int32_t  get_Count() const
	{
		if( !_eves || !_start ) return 0;

		int32_t    count = 0;
		for( const(EVERECORD)* p = _start; p; p = p.next ) count++;
		return count;
	}

	int32_t  get_Count( uint8_t kind, int32_t value ) const
	{
		if( !_eves ) return 0;

		int32_t count = 0;
		for( const(EVERECORD)* p = _start; p; p = p.next ){ if( p.kind == kind && p.value == value ) count++; }
		return count;
	}

	int32_t  get_Count( uint8_t unit_no ) const
	{
		if( !_eves ) return 0;

		int32_t count = 0;
		for( const(EVERECORD)* p = _start; p; p = p.next ){ if( p.unit_no == unit_no ) count++; }
		return count;
	}

	int32_t  get_Count( uint8_t unit_no, uint8_t kind ) const
	{
		if( !_eves ) return 0;

		int32_t count = 0;
		for( const(EVERECORD)* p = _start; p; p = p.next ){ if( p.unit_no == unit_no && p.kind == kind ) count++; }
		return count;
	}

	int32_t  get_Count( int32_t clock1, int32_t clock2, uint8_t unit_no ) const
	{
		if( !_eves ) return 0;

		const(EVERECORD)* p;
		for( p = _start; p; p = p.next )
		{
			if( p.unit_no == unit_no )
			{
				if(                                   p.clock            >= clock1 ) break;
				if( Evelist_Kind_IsTail( p.kind ) && p.clock + p.value >  clock1 ) break;
			}
		}

		int32_t count = 0;
		for(           ; p; p = p.next )
		{
			if( p.clock != clock1 && p.clock >= clock2 ) break;
			if( p.unit_no == unit_no ) count++;
		}
		return count;
	}
	int32_t get_Value( int32_t clock, uint8_t unit_no, uint8_t kind ) const
	{
		if( !_eves ) return 0;

		const(EVERECORD)* p;
		int32_t val = _DefaultKindValue( kind );

		for( p = _start; p; p = p.next )
		{
			if( p.clock > clock ) break;
			if( p.unit_no == unit_no && p.kind == kind ) val = p.value;
		}

		return val;
	}


	const(EVERECORD)* get_Records() const
	{
		if( !_eves ) return null;
		return _start;
	}

	bool Record_Add_i( int32_t clock, uint8_t unit_no, uint8_t kind, int32_t value )
	{
		if( !_eves ) return false;

		EVERECORD* p_new  = null;
		EVERECORD* p_prev = null;
		EVERECORD* p_next = null;

		// 空き検索
		for( int32_t r = 0; r < _eve_allocated_num; r++ )
		{
			if( _eves[ r ].kind == EVENTKIND_null ){ p_new = &_eves[ r ]; break; }
		}
		if( !p_new ) return false;

		// first.
		if( !_start )
		{
		}
		// top.
		else if( clock < _start.clock )
		{
			p_next = _start;
		}
		else
		{

			for( EVERECORD* p = _start; p; p = p.next )
			{
				if( p.clock == clock ) // 同時
				{
					for( ; true; p = p.next )
					{
						if( p.clock != clock                        ){ p_prev = p.prev; p_next = p; break; } 
						if( unit_no == p.unit_no && kind == p.kind ){ p_prev = p.prev; p_next = p.next; p.kind = EVENTKIND_null; break; } // 置き換え
						if( _ComparePriority( kind, p.kind ) < 0    ){ p_prev = p.prev; p_next = p; break; }// プライオリティを検査
						if( !p.next                                 ){ p_prev = p; break; }// 末端
					}
					break;
				}
				else if( p.clock > clock ){ p_prev = p.prev; p_next = p      ; break; } // 追い越した
				else if( !p.next         ){ p_prev = p; break; }// 末端
			}
		}

		_rec_set( p_new, p_prev, p_next, clock, unit_no, kind, value );

		// cut prev tail
		if( Evelist_Kind_IsTail( kind ) )
		{
			for( EVERECORD* p = p_new.prev; p; p = p.prev )
			{
				if( p.unit_no == unit_no && p.kind == kind )
				{
					if( clock < p.clock + p.value ) p.value = clock - p.clock;
					break;
				}
			}
		}

		// delete next
		if( Evelist_Kind_IsTail( kind ) )
		{
			for( EVERECORD* p = p_new.next; p && p.clock < clock + value; p = p.next )
			{
				if( p.unit_no == unit_no && p.kind == kind )
				{
					_rec_cut( p );
				}
			}
		}

		return true;
	}
	bool Record_Add_f( int32_t clock, uint8_t unit_no, uint8_t kind, float value_f )
	{
		int32_t value = *( cast(int32_t*)(&value_f) );
		return Record_Add_i( clock, unit_no, kind, value );
	}

	/////////////////////
	// linear
	/////////////////////

	bool Linear_Start()
	{
		if( !_eves ) return false;
		Clear(); _linear = 0;
		return true;
	}


	void Linear_Add_i(  int32_t clock, uint8_t unit_no, uint8_t kind, int32_t value )
	{
		EVERECORD* p = &_eves[ _linear ];

		p.clock      = clock  ;
		p.unit_no    = unit_no;
		p.kind       = kind   ;
		p.value      = value  ;

		_linear++;
	}

	void Linear_Add_f( int32_t clock, uint8_t unit_no, uint8_t kind, float value_f )
	{
		int32_t value = *( cast(int32_t*)(&value_f) );
		Linear_Add_i( clock, unit_no, kind, value );
	}

	void Linear_End( bool b_connect )
	{
		if( _eves[ 0 ].kind != EVENTKIND_null ) _start = &_eves[ 0 ];

		if( b_connect )
		{
			for( int32_t r = 1; r < _eve_allocated_num; r++ )
			{
				if( _eves[ r ].kind == EVENTKIND_null ) break;
				_eves[ r     ].prev = &_eves[ r - 1 ];
				_eves[ r - 1 ].next = &_eves[ r     ];
			}
		}
	}

	int32_t Record_Clock_Shift( int32_t clock, int32_t shift, uint8_t unit_no ) // can't be under 0.
	{
		if( !_eves  ) return 0;
		if( !_start ) return 0;
		if( !shift  ) return 0;

		int32_t          count = 0;
		int32_t          c;
		uint8_t           k;
		int32_t          v;
		EVERECORD*   p_next;
		EVERECORD*   p_prev;
		EVERECORD*   p = _start;


		if( shift < 0 )
		{
			for( ; p; p = p.next ){ if( p.clock >= clock ) break; }
			while( p )
			{
				if( p.unit_no == unit_no )
				{
					c      = p.clock + shift;
					k      = p.kind         ;
					v      = p.value        ;
					p_next = p.next;

					_rec_cut( p );
					if( c >= 0 ) Record_Add_i( c, unit_no, k, v );
					count++;

					p = p_next;
				}
				else
				{
					p = p.next;
				}
			}
		}
		else if( shift > 0 )
		{
			while( p.next ) p = p.next;
			while( p )
			{
				if( p.clock < clock ) break;

				if( p.unit_no == unit_no )
				{
					c      = p.clock + shift;
					k      = p.kind         ;
					v      = p.value        ;
					p_prev = p.prev;

					_rec_cut( p );
					Record_Add_i( c, unit_no, k, v );
					count++;

					p = p_prev;
				}
				else
				{
					p = p.prev;
				}
			}
		}
		return count;
	}
	int32_t Record_Value_Set( int32_t clock1, int32_t clock2, uint8_t unit_no, uint8_t kind, int32_t value )
	{
		if( !_eves  ) return 0;

		int32_t count = 0;

		for( EVERECORD* p = _start; p; p = p.next )
		{
			if( p.unit_no == unit_no && p.kind == kind && p.clock >= clock1 && p.clock < clock2 )
			{
				p.value = value;
				count++;
			}
		}

		return count;
	}
	int32_t Record_Value_Change( int32_t clock1, int32_t clock2, uint8_t unit_no, uint8_t kind, int32_t value )
	{
		if( !_eves  ) return 0;

		int32_t count = 0;

		int32_t max, min;

		switch( kind )
		{
		case EVENTKIND_null      : max =      0; min =   0; break;
		case EVENTKIND_ON        : max =    120; min = 120; break;
		case EVENTKIND_KEY       : max = 0xbfff; min =   0; break;
		case EVENTKIND_PAN_VOLUME: max =   0x80; min =   0; break;
		case EVENTKIND_PAN_TIME  : max =   0x80; min =   0; break;
		case EVENTKIND_VELOCITY  : max =   0x80; min =   0; break;
		case EVENTKIND_VOLUME    : max =   0x80; min =   0; break;
		default: max = 0; min = 0;
		}

		for( EVERECORD* p = _start; p; p = p.next )
		{
			if( p.unit_no == unit_no && p.kind == kind && p.clock >= clock1 )
			{
				if( clock2 == -1 || p.clock < clock2 )
				{
					p.value += value;
					if( p.value < min ) p.value = min;
					if( p.value > max ) p.value = max;
					count++;
				}
			}
		}

		return count;
	}
	int32_t Record_Value_Omit( uint8_t kind, int32_t value )
	{
		if( !_eves  ) return 0;

		int32_t count = 0;

		for( EVERECORD* p = _start; p; p = p.next )
		{
			if( p.kind == kind )
			{
				if(      p.value == value ){ _rec_cut( p ); count++; }
				else if( p.value >  value ){ p.value--;      count++; }
			}
		}
		return count;
	}
	int32_t Record_Value_Replace( uint8_t kind, int32_t old_value, int32_t new_value )
	{
		if( !_eves  ) return 0;

		int32_t count = 0;

		if( old_value == new_value ) return 0;
		if( old_value <  new_value )
		{
			for( EVERECORD* p = _start; p; p = p.next )
			{
				if( p.kind == kind )
				{
					if(      p.value == old_value                          ){ p.value = new_value; count++; }
					else if( p.value >  old_value && p.value <= new_value ){ p.value--;           count++; }
				}
			}
		}
		else
		{
			for( EVERECORD* p = _start; p; p = p.next )
			{
				if( p.kind == kind )
				{
					if(      p.value == old_value                          ){ p.value = new_value; count++; }
					else if( p.value <  old_value && p.value >= new_value ){ p.value++;           count++; }
				}
			}
		}

		return count;
	}

	int32_t Record_Delete( int32_t clock1, int32_t clock2, uint8_t unit_no, uint8_t kind )
	{
		if( !_eves  ) return 0;

		int32_t count = 0;

		for( EVERECORD* p = _start; p; p = p.next )
		{
			if( p.clock != clock1 && p.clock >= clock2 ) break;
			if( p.clock >= clock1 && p.unit_no == unit_no && p.kind == kind ){ _rec_cut( p ); count++; }
		}

		if( Evelist_Kind_IsTail( kind ) )
		{
			for( EVERECORD* p = _start; p; p = p.next )
			{
				if( p.clock >= clock1 ) break;
				if( p.unit_no == unit_no && p.kind == kind && p.clock + p.value > clock1 )
				{
					p.value = clock1 - p.clock;
					count++;
				}
			}
		}

		return count;
	}

	int32_t Record_Delete( int32_t clock1, int32_t clock2, uint8_t unit_no )
	{
		if( !_eves  ) return 0;

		int32_t count = 0;

		for( EVERECORD* p = _start; p; p = p.next )
		{
			if( p.clock != clock1 && p.clock >= clock2 ) break;
			if( p.clock >= clock1 && p.unit_no == unit_no ){ _rec_cut( p ); count++; }
		}

		for( EVERECORD* p = _start; p; p = p.next )
		{
			if( p.clock >= clock1 ) break;
			if( p.unit_no == unit_no && Evelist_Kind_IsTail( p.kind ) && p.clock + p.value > clock1 )
			{
				p.value = clock1 - p.clock;
				count++;
			}
		}

		return count;
	}
	int32_t Record_UnitNo_Miss( uint8_t unit_no ) // delete event has the unit-no
	{
		if( !_eves  ) return 0;

		int32_t count = 0;

		for( EVERECORD* p = _start; p; p = p.next )
		{
			if(      p.unit_no == unit_no ){ _rec_cut( p ); count++; }
			else if( p.unit_no >  unit_no ){ p.unit_no--;    count++; }
		}
		return count;
	}
	int32_t Record_UnitNo_Set( uint8_t unit_no ) // set the unit-no
	{
		if( !_eves  ) return 0;

		int32_t count = 0;
		for( EVERECORD* p = _start; p; p = p.next ){ p.unit_no = unit_no; count++; }
		return count;
	}
	int32_t Record_UnitNo_Replace( uint8_t old_u, uint8_t new_u ) // exchange unit
	{
		if( !_eves  ) return 0;

		int32_t count = 0;

		if( old_u == new_u ) return 0;
		if( old_u <  new_u )
		{
			for( EVERECORD* p = _start; p; p = p.next )
			{
				if(      p.unit_no == old_u                        ){ p.unit_no = new_u; count++; }
				else if( p.unit_no >  old_u && p.unit_no <= new_u ){ p.unit_no--;       count++; }
			}
		}
		else
		{
			for( EVERECORD* p = _start; p; p = p.next )
			{
				if(      p.unit_no == old_u                        ){ p.unit_no = new_u; count++; }
				else if( p.unit_no <  old_u && p.unit_no >= new_u ){ p.unit_no++;       count++; }
			}
		}

		return count;
	}

	int32_t  BeatClockOperation( int32_t rate )
	{
		if( !_eves  ) return 0;

		int32_t count = 0;

		for( EVERECORD* p = _start; p; p = p.next )
		{
			p.clock *= rate;
			if( Evelist_Kind_IsTail( p.kind ) ) p.value *= rate;
			count++;
		}

		return count;
	}

	// ------------
	// io
	// ------------


	bool io_Write( pxtnDescriptor *p_doc, int32_t rough ) const
	{
		int32_t eve_num        = get_Count();
		int32_t ralatived_size = 0;
		int32_t absolute       = 0;
		int32_t clock;
		int32_t value;

		for( const(EVERECORD)* p = get_Records(); p; p = p.next )
		{
			clock    = p.clock - absolute;

			ralatived_size += pxtnDescriptor_v_chk( p.clock );
			ralatived_size += 1;
			ralatived_size += 1;
			ralatived_size += pxtnDescriptor_v_chk( p.value );

			absolute = p.clock;
		}

		int32_t size = int32_t.sizeof + ralatived_size;
		if( !p_doc.w_asfile( &size   , int32_t.sizeof, 1 ) ) return false;
		if( !p_doc.w_asfile( &eve_num, int32_t.sizeof, 1 ) ) return false;

		absolute = 0;

		for( const(EVERECORD)* p = get_Records(); p; p = p.next )
		{
			clock    = p.clock - absolute;

			if( Evelist_Kind_IsTail( p.kind ) ) value = p.value / rough;
			else                                 value = p.value        ;

			if( !p_doc.v_w_asfile( clock / rough, null )    ) return false;
			if( !p_doc.w_asfile( &p.unit_no, uint8_t.sizeof, 1 ) ) return false;
			if( !p_doc.w_asfile( &p.kind   , uint8_t.sizeof, 1 ) ) return false;
			if( !p_doc.v_w_asfile( value        , null )    ) return false;

			absolute = p.clock;
		}

		return true;
	}

	pxtnERR io_Read( pxtnDescriptor *p_doc )
	{
		int32_t size     = 0;
		int32_t eve_num  = 0;

		if( !p_doc.r( &size   , 4, 1 ) ) return pxtnERR.pxtnERR_desc_r;
		if( !p_doc.r( &eve_num, 4, 1 ) ) return pxtnERR.pxtnERR_desc_r;

		int clock    = 0;
		int absolute = 0;
		uint8_t unit_no  = 0;
		uint8_t kind     = 0;
		int value    = 0;

		for( int32_t e = 0; e < eve_num; e++ )
		{
			if( !p_doc.v_r( &clock         ) ) return pxtnERR.pxtnERR_desc_r;
			if( !p_doc.r  ( &unit_no, 1, 1 ) ) return pxtnERR.pxtnERR_desc_r;
			if( !p_doc.r  ( &kind   , 1, 1 ) ) return pxtnERR.pxtnERR_desc_r;
			if( !p_doc.v_r( &value         ) ) return pxtnERR.pxtnERR_desc_r;
			absolute += clock;
			clock     = absolute;
			Linear_Add_i( clock, unit_no, kind, value );
		}

		return pxtnERR.pxtnOK;
	}

	int32_t io_Read_EventNum( pxtnDescriptor *p_doc ) const
	{
		int32_t size    = 0;
		int32_t eve_num = 0;

		if( !p_doc.r( &size   , 4, 1 ) ) return 0;
		if( !p_doc.r( &eve_num, 4, 1 ) ) return 0;

		int count   = 0;
		int clock   = 0;
		uint8_t unit_no = 0;
		uint8_t kind    = 0;
		int value   = 0;

		for( int32_t e = 0; e < eve_num; e++ )
		{
			if( !p_doc.v_r( &clock         ) ) return 0;
			if( !p_doc.r  ( &unit_no, 1, 1 ) ) return 0;
			if( !p_doc.r  ( &kind   , 1, 1 ) ) return 0;
			if( !p_doc.v_r( &value         ) ) return 0;
			count++;
		}
		if( count != eve_num ) return 0;

		return eve_num;
	}

	bool x4x_Read_Start()
	{
		if( !_eves ) return false;
		Clear();
		_linear    =    0;
		_p_x4x_rec = null;
		return true;
	}

	void x4x_Read_NewKind()
	{
		_p_x4x_rec = null;
	}
	void x4x_Read_Add( int32_t clock, uint8_t unit_no, uint8_t kind, int32_t value )
	{
		EVERECORD* p_new  = null;
		EVERECORD* p_prev = null;
		EVERECORD* p_next = null;

		p_new = &_eves[ _linear++ ];

		// first.
		if( !_start )
		{
		}
		// top
		else if( clock < _start.clock )
		{
			p_next = _start;
		}
		else
		{
			EVERECORD* p;

			if( _p_x4x_rec ) p = _p_x4x_rec;
			else             p = _start    ;

			for( ; p; p = p.next )
			{
				if( p.clock == clock ) // 同時
				{
					for( ; true; p = p.next )
					{
						if( p.clock != clock                        ){ p_prev = p.prev; p_next = p; break; } 
						if( unit_no == p.unit_no && kind == p.kind ){ p_prev = p.prev; p_next = p.next; p.kind = EVENTKIND_null; break; } // 置き換え
						if( _ComparePriority( kind, p.kind ) < 0    ){ p_prev = p.prev; p_next = p; break; }// プライオリティを検査
						if( !p.next                                 ){ p_prev = p; break; }// 末端
					}
					break;
				}
				else if( p.clock > clock ){ p_prev = p.prev; p_next = p; break; } // 追い越した
				else if( !p.next         ){ p_prev = p; break; }// 末端
			}
		}
		_rec_set( p_new, p_prev, p_next, clock, unit_no, kind, value );

		_p_x4x_rec = p_new;
	}

	// write event.
	pxtnERR io_Unit_Read_x4x_EVENT( pxtnDescriptor *p_doc, bool bTailAbsolute, bool bCheckRRR )
	{
		_x4x_EVENTSTRUCT evnt     ={0};
		int          clock    = 0;
		int          value    = 0;
		int          absolute = 0;
		int          e        = 0;
		int          size     = 0;

		if( !p_doc.r( &size, 4,                          1 ) ) return pxtnERR.pxtnERR_desc_r;
		if( !p_doc.r( &evnt,  _x4x_EVENTSTRUCT.sizeof, 1 ) ) return pxtnERR.pxtnERR_desc_r;

		if( evnt.data_num != 2               ) return pxtnERR.pxtnERR_fmt_unknown;
		if( evnt.event_kind >= EVENTKIND_NUM ) return pxtnERR.pxtnERR_fmt_unknown;
		if( bCheckRRR && evnt.rrr            ) return pxtnERR.pxtnERR_fmt_unknown;

		absolute = 0;
		for( e = 0; e < cast(int32_t)evnt.event_num; e++ )
		{
			if( !p_doc.v_r( &clock ) ) break;
			if( !p_doc.v_r( &value ) ) break;
			absolute += clock;
			clock     = absolute;
			x4x_Read_Add( clock, cast(uint8_t)evnt.unit_index, cast(uint8_t)evnt.event_kind, value );
			if( bTailAbsolute && Evelist_Kind_IsTail( evnt.event_kind ) ) absolute += value;
		}
		if( e != evnt.event_num ) return pxtnERR.pxtnERR_desc_broken;

		x4x_Read_NewKind();

		return pxtnERR.pxtnOK;
	}
	pxtnERR io_Read_x4x_EventNum( pxtnDescriptor *p_doc, int32_t* p_num ) const
	{
		if( !p_doc || !p_num ) return pxtnERR.pxtnERR_param;

		_x4x_EVENTSTRUCT evnt = {0};
		int          work =  0 ;
		int          e    =  0 ;
		int          size =  0 ;

		if( !p_doc.r( &size, 4,                          1 ) ) return pxtnERR.pxtnERR_desc_r;
		if( !p_doc.r( &evnt,  _x4x_EVENTSTRUCT.sizeof, 1 ) ) return pxtnERR.pxtnERR_desc_r;

		// support only 2
		if( evnt.data_num != 2 ) return pxtnERR.pxtnERR_fmt_unknown;

		for( e = 0; e < cast(int32_t)evnt.event_num; e++ )
		{
			if( !p_doc.v_r( &work ) ) break;
			if( !p_doc.v_r( &work ) ) break;
		}
		if( e != evnt.event_num ) return pxtnERR.pxtnERR_desc_broken;

		*p_num = evnt.event_num;

		return pxtnERR.pxtnOK;
	}
};

bool Evelist_Kind_IsTail( int32_t kind );
