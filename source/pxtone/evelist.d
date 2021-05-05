module pxtone.evelist;

import pxtone.descriptor;
import pxtone.error;
import pxtone.mem;

///////////////////////
// global
///////////////////////

bool Evelist_Kind_IsTail(int kind) nothrow @safe {
	if (kind == EVENTKIND.ON || kind == EVENTKIND.PORTAMENT) {
		return true;
	}
	return false;
}

enum EVENTKIND {
	NULL = 0, //  0

	ON, //  1
	KEY, //  2
	PAN_VOLUME, //  3
	VELOCITY, //  4
	VOLUME, //  5
	PORTAMENT, //  6
	BEATCLOCK, //  7
	BEATTEMPO, //  8
	BEATNUM, //  9
	REPEAT, // 10
	LAST, // 11
	VOICENO, // 12
	GROUPNO, // 13
	TUNING, // 14
	PAN_TIME, // 15

	NUM, // 16
}

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

struct EVERECORD {
	ubyte kind;
	ubyte unit_no;
	ubyte reserve1;
	ubyte reserve2;
	int value;
	int clock;
	EVERECORD* prev;
	EVERECORD* next;
}

int _DefaultKindValue(ubyte kind) nothrow @system {
	switch (kind) {
		//	case EVENTKIND.ON        : return ;
	case EVENTKIND.KEY:
		return EVENTDEFAULT_KEY;
	case EVENTKIND.PAN_VOLUME:
		return EVENTDEFAULT_PAN_VOLUME;
	case EVENTKIND.VELOCITY:
		return EVENTDEFAULT_VELOCITY;
	case EVENTKIND.VOLUME:
		return EVENTDEFAULT_VOLUME;
	case EVENTKIND.PORTAMENT:
		return EVENTDEFAULT_PORTAMENT;
	case EVENTKIND.BEATCLOCK:
		return EVENTDEFAULT_BEATCLOCK;
	case EVENTKIND.BEATTEMPO:
		return EVENTDEFAULT_BEATTEMPO;
	case EVENTKIND.BEATNUM:
		return EVENTDEFAULT_BEATNUM;
		//	case EVENTKIND.REPEAT    : return ;
		//	case EVENTKIND.LAST      : return ;
	case EVENTKIND.VOICENO:
		return EVENTDEFAULT_VOICENO;
	case EVENTKIND.GROUPNO:
		return EVENTDEFAULT_GROUPNO;
	case EVENTKIND.TUNING: {
			float tuning;
			tuning = EVENTDEFAULT_TUNING;
			return *(cast(int*)&tuning);
		}
	case EVENTKIND.PAN_TIME:
		return EVENTDEFAULT_PAN_TIME;
	default:
		break;
	}
	return 0;
}

int _ComparePriority(ubyte kind1, ubyte kind2) nothrow @safe {
	static const int[EVENTKIND.NUM] priority_table = [0, // EVENTKIND.NULL  = 0
		50, // EVENTKIND.ON
		40, // EVENTKIND.KEY
		60, // EVENTKIND.PAN_VOLUME
		70, // EVENTKIND.VELOCITY
		80, // EVENTKIND.VOLUME
		30, // EVENTKIND.PORTAMENT
		0, // EVENTKIND.BEATCLOCK
		0, // EVENTKIND.BEATTEMPO
		0, // EVENTKIND.BEATNUM
		0, // EVENTKIND.REPEAT
		255, // EVENTKIND.LAST
		10, // EVENTKIND.VOICENO
		20, // EVENTKIND.GROUPNO
		90, // EVENTKIND.TUNING
		100, // EVENTKIND.PAN_TIME
		];

	return priority_table[kind1] - priority_table[kind2];
}

// event struct(12byte) =================
struct _x4x_EVENTSTRUCT {
	ushort unit_index;
	ushort event_kind;
	ushort data_num; // １イベントのデータ数。現在は 2 ( clock / volume ）
	ushort rrr;
	uint event_num;
}

//--------------------------------

struct pxtnEvelist {

private:

	int _eve_allocated_num;
	EVERECORD[] _eves;
	EVERECORD* _start;
	int _linear;

	EVERECORD* _p_x4x_rec;

	void _rec_set(EVERECORD* p_rec, EVERECORD* prev, EVERECORD* next, int clock, ubyte unit_no, ubyte kind, int value) nothrow @safe {
		if (prev) {
			prev.next = p_rec;
		} else {
			_start = p_rec;
		}
		if (next) {
			next.prev = p_rec;
		}

		p_rec.next = next;
		p_rec.prev = prev;
		p_rec.clock = clock;
		p_rec.kind = kind;
		p_rec.unit_no = unit_no;
		p_rec.value = value;
	}

	void _rec_cut(EVERECORD* p_rec) nothrow @safe {
		if (p_rec.prev) {
			p_rec.prev.next = p_rec.next;
		} else {
			_start = p_rec.next;
		}
		if (p_rec.next) {
			p_rec.next.prev = p_rec.prev;
		}
		p_rec.kind = EVENTKIND.NULL;
	}

public:

	void Release() nothrow @system {
		if (_eves) {
			deallocate(_eves);
		}
		_eves = null;
		_start = null;
		_eve_allocated_num = 0;
	}

	void Clear() nothrow @system {
		if (_eves) {
			_eves[0 .. _eve_allocated_num] = EVERECORD.init;
		}
		_start = null;
	}

	~this() nothrow @system {
		Release();
	}

	bool Allocate(int max_event_num) nothrow @system {
		Release();
		_eves = allocate!EVERECORD(max_event_num);
		if (!(_eves)) {
			return false;
		}
		_eves[0 .. max_event_num] = EVERECORD.init;
		_eve_allocated_num = max_event_num;
		return true;
	}

	int get_Num_Max() const nothrow @safe {
		if (!_eves) {
			return 0;
		}
		return _eve_allocated_num;
	}

	int get_Max_Clock() const nothrow @safe {
		int max_clock = 0;
		int clock;

		for (const(EVERECORD)* p = _start; p; p = p.next) {
			if (Evelist_Kind_IsTail(p.kind)) {
				clock = p.clock + p.value;
			} else {
				clock = p.clock;
			}
			if (clock > max_clock) {
				max_clock = clock;
			}
		}

		return max_clock;

	}

	int get_Count() const nothrow @safe {
		if (!_eves || !_start) {
			return 0;
		}

		int count = 0;
		for (const(EVERECORD)* p = _start; p; p = p.next) {
			count++;
		}
		return count;
	}

	int get_Count(ubyte kind, int value) const nothrow @safe {
		if (!_eves) {
			return 0;
		}

		int count = 0;
		for (const(EVERECORD)* p = _start; p; p = p.next) {
			if (p.kind == kind && p.value == value) {
				count++;
			}
		}
		return count;
	}

	int get_Count(ubyte unit_no) const nothrow @safe {
		if (!_eves) {
			return 0;
		}

		int count = 0;
		for (const(EVERECORD)* p = _start; p; p = p.next) {
			if (p.unit_no == unit_no) {
				count++;
			}
		}
		return count;
	}

	int get_Count(ubyte unit_no, ubyte kind) const nothrow @safe {
		if (!_eves) {
			return 0;
		}

		int count = 0;
		for (const(EVERECORD)* p = _start; p; p = p.next) {
			if (p.unit_no == unit_no && p.kind == kind) {
				count++;
			}
		}
		return count;
	}

	int get_Count(int clock1, int clock2, ubyte unit_no) const nothrow @safe {
		if (!_eves) {
			return 0;
		}

		const(EVERECORD)* p;
		for (p = _start; p; p = p.next) {
			if (p.unit_no == unit_no) {
				if (p.clock >= clock1) {
					break;
				}
				if (Evelist_Kind_IsTail(p.kind) && p.clock + p.value > clock1) {
					break;
				}
			}
		}

		int count = 0;
		for (; p; p = p.next) {
			if (p.clock != clock1 && p.clock >= clock2) {
				break;
			}
			if (p.unit_no == unit_no) {
				count++;
			}
		}
		return count;
	}

	int get_Value(int clock, ubyte unit_no, ubyte kind) const nothrow @system {
		if (!_eves) {
			return 0;
		}

		const(EVERECORD)* p;
		int val = _DefaultKindValue(kind);

		for (p = _start; p; p = p.next) {
			if (p.clock > clock) {
				break;
			}
			if (p.unit_no == unit_no && p.kind == kind) {
				val = p.value;
			}
		}

		return val;
	}

	const(EVERECORD)* get_Records() const nothrow @safe {
		if (!_eves) {
			return null;
		}
		return _start;
	}

	bool Record_Add_i(int clock, ubyte unit_no, ubyte kind, int value) nothrow @system {
		if (!_eves) {
			return false;
		}

		EVERECORD* p_new = null;
		EVERECORD* p_prev = null;
		EVERECORD* p_next = null;

		// 空き検索
		for (int r = 0; r < _eve_allocated_num; r++) {
			if (_eves[r].kind == EVENTKIND.NULL) {
				p_new = &_eves[r];
				break;
			}
		}
		if (!p_new) {
			return false;
		}

		// first.
		if (!_start) {
		}  // top.
		else if (clock < _start.clock) {
			p_next = _start;
		} else {

			for (EVERECORD* p = _start; p; p = p.next) {
				// 同時 
				if (p.clock == clock) {
					for (; true; p = p.next) {
						if (p.clock != clock) {
							p_prev = p.prev;
							p_next = p;
							break;
						}
						if (unit_no == p.unit_no && kind == p.kind) {
							p_prev = p.prev;
							p_next = p.next;
							p.kind = EVENTKIND.NULL;
							break;
						} // 置き換え
						if (_ComparePriority(kind, p.kind) < 0) {
							p_prev = p.prev;
							p_next = p;
							break;
						} // プライオリティを検査
						if (!p.next) {
							p_prev = p;
							break;
						} // 末端
					}
					break;
				} else if (p.clock > clock) {
					p_prev = p.prev;
					p_next = p;
					break;
				}  // 追い越した
				else if (!p.next) {
					p_prev = p;
					break;
				} // 末端
			}
		}

		_rec_set(p_new, p_prev, p_next, clock, unit_no, kind, value);

		// cut prev tail
		if (Evelist_Kind_IsTail(kind)) {
			for (EVERECORD* p = p_new.prev; p; p = p.prev) {
				if (p.unit_no == unit_no && p.kind == kind) {
					if (clock < p.clock + p.value) {
						p.value = clock - p.clock;
					}
					break;
				}
			}
		}

		// delete next
		if (Evelist_Kind_IsTail(kind)) {
			for (EVERECORD* p = p_new.next; p && p.clock < clock + value; p = p.next) {
				if (p.unit_no == unit_no && p.kind == kind) {
					_rec_cut(p);
				}
			}
		}

		return true;
	}

	bool Record_Add_f(int clock, ubyte unit_no, ubyte kind, float value_f) nothrow @system {
		int value = *(cast(int*)(&value_f));
		return Record_Add_i(clock, unit_no, kind, value);
	}

	/////////////////////
	// linear
	/////////////////////

	bool Linear_Start() nothrow @system {
		if (!_eves) {
			return false;
		}
		Clear();
		_linear = 0;
		return true;
	}

	void Linear_Add_i(int clock, ubyte unit_no, ubyte kind, int value) nothrow @system {
		EVERECORD* p = &_eves[_linear];

		p.clock = clock;
		p.unit_no = unit_no;
		p.kind = kind;
		p.value = value;

		_linear++;
	}

	void Linear_Add_f(int clock, ubyte unit_no, ubyte kind, float value_f) nothrow @system {
		int value = *(cast(int*)(&value_f));
		Linear_Add_i(clock, unit_no, kind, value);
	}

	void Linear_End(bool b_connect) nothrow @system {
		if (_eves[0].kind != EVENTKIND.NULL) {
			_start = &_eves[0];
		}

		if (b_connect) {
			for (int r = 1; r < _eve_allocated_num; r++) {
				if (_eves[r].kind == EVENTKIND.NULL) {
					break;
				}
				_eves[r].prev = &_eves[r - 1];
				_eves[r - 1].next = &_eves[r];
			}
		}
	}

	int Record_Clock_Shift(int clock, int shift, ubyte unit_no) nothrow @system  // can't be under 0.
	{
		if (!_eves) {
			return 0;
		}
		if (!_start) {
			return 0;
		}
		if (!shift) {
			return 0;
		}

		int count = 0;
		int c;
		ubyte k;
		int v;
		EVERECORD* p_next;
		EVERECORD* p_prev;
		EVERECORD* p = _start;

		if (shift < 0) {
			for (; p; p = p.next) {
				if (p.clock >= clock) {
					break;
				}
			}
			while (p) {
				if (p.unit_no == unit_no) {
					c = p.clock + shift;
					k = p.kind;
					v = p.value;
					p_next = p.next;

					_rec_cut(p);
					if (c >= 0) {
						Record_Add_i(c, unit_no, k, v);
					}
					count++;

					p = p_next;
				} else {
					p = p.next;
				}
			}
		} else if (shift > 0) {
			while (p.next) {
				p = p.next;
			}
			while (p) {
				if (p.clock < clock) {
					break;
				}

				if (p.unit_no == unit_no) {
					c = p.clock + shift;
					k = p.kind;
					v = p.value;
					p_prev = p.prev;

					_rec_cut(p);
					Record_Add_i(c, unit_no, k, v);
					count++;

					p = p_prev;
				} else {
					p = p.prev;
				}
			}
		}
		return count;
	}

	int Record_Value_Set(int clock1, int clock2, ubyte unit_no, ubyte kind, int value) nothrow @safe {
		if (!_eves) {
			return 0;
		}

		int count = 0;

		for (EVERECORD* p = _start; p; p = p.next) {
			if (p.unit_no == unit_no && p.kind == kind && p.clock >= clock1 && p.clock < clock2) {
				p.value = value;
				count++;
			}
		}

		return count;
	}

	int Record_Value_Change(int clock1, int clock2, ubyte unit_no, ubyte kind, int value) nothrow @safe {
		if (!_eves) {
			return 0;
		}

		int count = 0;

		int max, min;

		switch (kind) {
		case EVENTKIND.NULL:
			max = 0;
			min = 0;
			break;
		case EVENTKIND.ON:
			max = 120;
			min = 120;
			break;
		case EVENTKIND.KEY:
			max = 0xbfff;
			min = 0;
			break;
		case EVENTKIND.PAN_VOLUME:
			max = 0x80;
			min = 0;
			break;
		case EVENTKIND.PAN_TIME:
			max = 0x80;
			min = 0;
			break;
		case EVENTKIND.VELOCITY:
			max = 0x80;
			min = 0;
			break;
		case EVENTKIND.VOLUME:
			max = 0x80;
			min = 0;
			break;
		default:
			max = 0;
			min = 0;
		}

		for (EVERECORD* p = _start; p; p = p.next) {
			if (p.unit_no == unit_no && p.kind == kind && p.clock >= clock1) {
				if (clock2 == -1 || p.clock < clock2) {
					p.value += value;
					if (p.value < min) {
						p.value = min;
					}
					if (p.value > max) {
						p.value = max;
					}
					count++;
				}
			}
		}

		return count;
	}

	int Record_Value_Omit(ubyte kind, int value) nothrow @safe {
		if (!_eves) {
			return 0;
		}

		int count = 0;

		for (EVERECORD* p = _start; p; p = p.next) {
			if (p.kind == kind) {
				if (p.value == value) {
					_rec_cut(p);
					count++;
				} else if (p.value > value) {
					p.value--;
					count++;
				}
			}
		}
		return count;
	}

	int Record_Value_Replace(ubyte kind, int old_value, int new_value) nothrow @safe {
		if (!_eves) {
			return 0;
		}

		int count = 0;

		if (old_value == new_value) {
			return 0;
		}
		if (old_value < new_value) {
			for (EVERECORD* p = _start; p; p = p.next) {
				if (p.kind == kind) {
					if (p.value == old_value) {
						p.value = new_value;
						count++;
					} else if (p.value > old_value && p.value <= new_value) {
						p.value--;
						count++;
					}
				}
			}
		} else {
			for (EVERECORD* p = _start; p; p = p.next) {
				if (p.kind == kind) {
					if (p.value == old_value) {
						p.value = new_value;
						count++;
					} else if (p.value < old_value && p.value >= new_value) {
						p.value++;
						count++;
					}
				}
			}
		}

		return count;
	}

	int Record_Delete(int clock1, int clock2, ubyte unit_no, ubyte kind) nothrow @safe {
		if (!_eves) {
			return 0;
		}

		int count = 0;

		for (EVERECORD* p = _start; p; p = p.next) {
			if (p.clock != clock1 && p.clock >= clock2) {
				break;
			}
			if (p.clock >= clock1 && p.unit_no == unit_no && p.kind == kind) {
				_rec_cut(p);
				count++;
			}
		}

		if (Evelist_Kind_IsTail(kind)) {
			for (EVERECORD* p = _start; p; p = p.next) {
				if (p.clock >= clock1) {
					break;
				}
				if (p.unit_no == unit_no && p.kind == kind && p.clock + p.value > clock1) {
					p.value = clock1 - p.clock;
					count++;
				}
			}
		}

		return count;
	}

	int Record_Delete(int clock1, int clock2, ubyte unit_no) nothrow @safe {
		if (!_eves) {
			return 0;
		}

		int count = 0;

		for (EVERECORD* p = _start; p; p = p.next) {
			if (p.clock != clock1 && p.clock >= clock2) {
				break;
			}
			if (p.clock >= clock1 && p.unit_no == unit_no) {
				_rec_cut(p);
				count++;
			}
		}

		for (EVERECORD* p = _start; p; p = p.next) {
			if (p.clock >= clock1) {
				break;
			}
			if (p.unit_no == unit_no && Evelist_Kind_IsTail(p.kind) && p.clock + p.value > clock1) {
				p.value = clock1 - p.clock;
				count++;
			}
		}

		return count;
	}

	int Record_UnitNo_Miss(ubyte unit_no) nothrow @safe  // delete event has the unit-no
	{
		if (!_eves) {
			return 0;
		}

		int count = 0;

		for (EVERECORD* p = _start; p; p = p.next) {
			if (p.unit_no == unit_no) {
				_rec_cut(p);
				count++;
			} else if (p.unit_no > unit_no) {
				p.unit_no--;
				count++;
			}
		}
		return count;
	}

	int Record_UnitNo_Set(ubyte unit_no) nothrow @safe  // set the unit-no
	{
		if (!_eves) {
			return 0;
		}

		int count = 0;
		for (EVERECORD* p = _start; p; p = p.next) {
			p.unit_no = unit_no;
			count++;
		}
		return count;
	}

	int Record_UnitNo_Replace(ubyte old_u, ubyte new_u) nothrow @safe  // exchange unit
	{
		if (!_eves) {
			return 0;
		}

		int count = 0;

		if (old_u == new_u) {
			return 0;
		}
		if (old_u < new_u) {
			for (EVERECORD* p = _start; p; p = p.next) {
				if (p.unit_no == old_u) {
					p.unit_no = new_u;
					count++;
				} else if (p.unit_no > old_u && p.unit_no <= new_u) {
					p.unit_no--;
					count++;
				}
			}
		} else {
			for (EVERECORD* p = _start; p; p = p.next) {
				if (p.unit_no == old_u) {
					p.unit_no = new_u;
					count++;
				} else if (p.unit_no < old_u && p.unit_no >= new_u) {
					p.unit_no++;
					count++;
				}
			}
		}

		return count;
	}

	int BeatClockOperation(int rate) nothrow @safe {
		if (!_eves) {
			return 0;
		}

		int count = 0;

		for (EVERECORD* p = _start; p; p = p.next) {
			p.clock *= rate;
			if (Evelist_Kind_IsTail(p.kind)) {
				p.value *= rate;
			}
			count++;
		}

		return count;
	}

	// ------------
	// io
	// ------------

	bool io_Write(ref pxtnDescriptor p_doc, int rough) const nothrow @system {
		int eve_num = get_Count();
		int ralatived_size = 0;
		int absolute = 0;
		int clock;
		int value;

		for (const(EVERECORD)* p = get_Records(); p; p = p.next) {
			clock = p.clock - absolute;

			ralatived_size += pxtnDescriptor_v_chk(p.clock);
			ralatived_size += 1;
			ralatived_size += 1;
			ralatived_size += pxtnDescriptor_v_chk(p.value);

			absolute = p.clock;
		}

		size_t size = int.sizeof + ralatived_size;
		if (!p_doc.w_asfile(&size, int.sizeof, 1)) {
			return false;
		}
		if (!p_doc.w_asfile(&eve_num, int.sizeof, 1)) {
			return false;
		}

		absolute = 0;

		for (const(EVERECORD)* p = get_Records(); p; p = p.next) {
			clock = p.clock - absolute;

			if (Evelist_Kind_IsTail(p.kind)) {
				value = p.value / rough;
			} else {
				value = p.value;
			}

			if (!p_doc.v_w_asfile(clock / rough, null)) {
				return false;
			}
			if (!p_doc.w_asfile(&p.unit_no, ubyte.sizeof, 1)) {
				return false;
			}
			if (!p_doc.w_asfile(&p.kind, ubyte.sizeof, 1)) {
				return false;
			}
			if (!p_doc.v_w_asfile(value, null)) {
				return false;
			}

			absolute = p.clock;
		}

		return true;
	}

	pxtnERR io_Read(ref pxtnDescriptor p_doc) nothrow @system {
		int size = 0;
		int eve_num = 0;

		if (!p_doc.r(size)) {
			return pxtnERR.desc_r;
		}
		if (!p_doc.r(eve_num)) {
			return pxtnERR.desc_r;
		}

		int clock = 0;
		int absolute = 0;
		ubyte unit_no = 0;
		ubyte kind = 0;
		int value = 0;

		for (int e = 0; e < eve_num; e++) {
			if (!p_doc.v_r(&clock)) {
				return pxtnERR.desc_r;
			}
			if (!p_doc.r(unit_no)) {
				return pxtnERR.desc_r;
			}
			if (!p_doc.r(kind)) {
				return pxtnERR.desc_r;
			}
			if (!p_doc.v_r(&value)) {
				return pxtnERR.desc_r;
			}
			absolute += clock;
			clock = absolute;
			Linear_Add_i(clock, unit_no, kind, value);
		}

		return pxtnERR.OK;
	}

	int io_Read_EventNum(ref pxtnDescriptor p_doc) const nothrow @system {
		int size = 0;
		int eve_num = 0;

		if (!p_doc.r(size)) {
			return 0;
		}
		if (!p_doc.r(eve_num)) {
			return 0;
		}

		int count = 0;
		int clock = 0;
		ubyte unit_no = 0;
		ubyte kind = 0;
		int value = 0;

		for (int e = 0; e < eve_num; e++) {
			if (!p_doc.v_r(&clock)) {
				return 0;
			}
			if (!p_doc.r(unit_no)) {
				return 0;
			}
			if (!p_doc.r(kind)) {
				return 0;
			}
			if (!p_doc.v_r(&value)) {
				return 0;
			}
			count++;
		}
		if (count != eve_num) {
			return 0;
		}

		return eve_num;
	}

	bool x4x_Read_Start() nothrow @system {
		if (!_eves) {
			return false;
		}
		Clear();
		_linear = 0;
		_p_x4x_rec = null;
		return true;
	}

	void x4x_Read_NewKind() nothrow @safe {
		_p_x4x_rec = null;
	}

	void x4x_Read_Add(int clock, ubyte unit_no, ubyte kind, int value) nothrow @system {
		EVERECORD* p_new = null;
		EVERECORD* p_prev = null;
		EVERECORD* p_next = null;

		p_new = &_eves[_linear++];

		// first.
		if (!_start) {
		}  // top
		else if (clock < _start.clock) {
			p_next = _start;
		} else {
			EVERECORD* p;

			if (_p_x4x_rec) {
				p = _p_x4x_rec;
			} else {
				p = _start;
			}

			for (; p; p = p.next) {
				// 同時
				if (p.clock == clock) {
					for (; true; p = p.next) {
						if (p.clock != clock) {
							p_prev = p.prev;
							p_next = p;
							break;
						}
						if (unit_no == p.unit_no && kind == p.kind) {
							p_prev = p.prev;
							p_next = p.next;
							p.kind = EVENTKIND.NULL;
							break;
						} // 置き換え
						if (_ComparePriority(kind, p.kind) < 0) {
							p_prev = p.prev;
							p_next = p;
							break;
						} // プライオリティを検査
						if (!p.next) {
							p_prev = p;
							break;
						} // 末端
					}
					break;
				} else if (p.clock > clock) {
					p_prev = p.prev;
					p_next = p;
					break;
				}  // 追い越した
				else if (!p.next) {
					p_prev = p;
					break;
				} // 末端
			}
		}
		_rec_set(p_new, p_prev, p_next, clock, unit_no, kind, value);

		_p_x4x_rec = p_new;
	}

	// write event.
	pxtnERR io_Unit_Read_x4x_EVENT(ref pxtnDescriptor p_doc, bool bTailAbsolute, bool bCheckRRR) nothrow @system {
		_x4x_EVENTSTRUCT evnt;
		int clock = 0;
		int value = 0;
		int absolute = 0;
		int e = 0;
		int size = 0;

		if (!p_doc.r(size)) {
			return pxtnERR.desc_r;
		}
		if (!p_doc.r(evnt)) {
			return pxtnERR.desc_r;
		}

		if (evnt.data_num != 2) {
			return pxtnERR.fmt_unknown;
		}
		if (evnt.event_kind >= EVENTKIND.NUM) {
			return pxtnERR.fmt_unknown;
		}
		if (bCheckRRR && evnt.rrr) {
			return pxtnERR.fmt_unknown;
		}

		absolute = 0;
		for (e = 0; e < cast(int) evnt.event_num; e++) {
			if (!p_doc.v_r(&clock)) {
				break;
			}
			if (!p_doc.v_r(&value)) {
				break;
			}
			absolute += clock;
			clock = absolute;
			x4x_Read_Add(clock, cast(ubyte) evnt.unit_index, cast(ubyte) evnt.event_kind, value);
			if (bTailAbsolute && Evelist_Kind_IsTail(evnt.event_kind)) {
				absolute += value;
			}
		}
		if (e != evnt.event_num) {
			return pxtnERR.desc_broken;
		}

		x4x_Read_NewKind();

		return pxtnERR.OK;
	}

	pxtnERR io_Read_x4x_EventNum(ref pxtnDescriptor p_doc, int* p_num) const nothrow @system {
		if (!p_num) {
			return pxtnERR.param;
		}

		_x4x_EVENTSTRUCT evnt;
		int work = 0;
		int e = 0;
		int size = 0;

		if (!p_doc.r(size)) {
			return pxtnERR.desc_r;
		}
		if (!p_doc.r(evnt)) {
			return pxtnERR.desc_r;
		}

		// support only 2
		if (evnt.data_num != 2) {
			return pxtnERR.fmt_unknown;
		}

		for (e = 0; e < cast(int) evnt.event_num; e++) {
			if (!p_doc.v_r(&work)) {
				break;
			}
			if (!p_doc.v_r(&work)) {
				break;
			}
		}
		if (e != evnt.event_num) {
			return pxtnERR.desc_broken;
		}

		*p_num = evnt.event_num;

		return pxtnERR.OK;
	}
}
