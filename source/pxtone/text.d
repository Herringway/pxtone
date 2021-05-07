module pxtone.text;
// '12/03/03

import pxtone.descriptor;
import pxtone.mem;

bool _read4_malloc(char[]* pp, int* p_buf_size, ref pxtnDescriptor p_doc) nothrow @system {
	if (!pp) {
		return false;
	}
	if (!p_doc.r(p_buf_size[0 .. 1])) {
		return false;
	}
	if (*p_buf_size < 0) {
		return false;
	}

	bool b_ret = false;

	*pp = allocate!char(*p_buf_size + 1);
	if (!(*pp)) {
		return false;
	}

	(*pp)[0 .. *p_buf_size + 1] = 0;

	if (*p_buf_size) {
		if (!p_doc.r((*pp)[0 .. *p_buf_size])) {
			goto term;
		}
	}

	b_ret = true;
term:
	if (!b_ret) {
		deallocate(*pp);
		*pp = null;
	}

	return b_ret;
}

bool _write4(const char[] p, ref pxtnDescriptor p_doc) nothrow @system {
	if (!p_doc.w_asfile(cast(int)p.length)) {
		return false;
	}
	if (!p_doc.w_asfile(p)) {
		return false;
	}
	return true;
}

struct pxtnText {
private:
	char[] _p_comment_buf;
	int _comment_size;

	char[] _p_name_buf;
	int _name_size;

public:
	 ~this() nothrow @system {
		deallocate(_p_comment_buf);
		_comment_size = 0;
		deallocate(_p_name_buf);
		_name_size = 0;
	}

	bool set_comment_buf(const(char)* comment, int buf_size) nothrow @system {
		if (!comment) {
			return false;
		}
		if (_p_comment_buf) {
			deallocate(_p_comment_buf);
		}
		_p_comment_buf = null;
		if (buf_size <= 0) {
			_comment_size = 0;
			return true;
		}
		_p_comment_buf = allocate!char(buf_size + 1);
		if (!(_p_comment_buf)) {
			return false;
		}
		_p_comment_buf[0 .. buf_size] = comment[0 .. buf_size];
		_p_comment_buf[buf_size] = '\0';
		_comment_size = buf_size;
		return true;
	}

	const(char)[] get_comment_buf() const nothrow @system {
		return _p_comment_buf[0 .. _comment_size];
	}

	bool is_comment_buf() const nothrow @safe {
		if (_comment_size > 0) {
			return true;
		}
		return false;
	}

	bool set_name_buf(const(char)* name, int buf_size) nothrow @system {
		if (!name) {
			return false;
		}
		if (_p_name_buf) {
			deallocate(_p_name_buf);
		}
		_p_name_buf = null;
		if (buf_size <= 0) {
			_name_size = 0;
			return true;
		}
		_p_name_buf = allocate!char(buf_size + 1);
		if (!(_p_name_buf)) {
			return false;
		}
		_p_name_buf[0 .. buf_size] = name[0 .. buf_size];
		_p_name_buf[buf_size] = '\0';
		_name_size = buf_size;
		return true;
	}

	const(char)[] get_name_buf() const nothrow @system {
		return _p_name_buf[0 .. _name_size];
	}

	bool is_name_buf() const nothrow @safe {
		if (_name_size > 0) {
			return true;
		}
		return false;
	}

	bool Comment_r(ref pxtnDescriptor p_doc) nothrow @system {
		return _read4_malloc(&_p_comment_buf, &_comment_size, p_doc);
	}

	bool Comment_w(ref pxtnDescriptor p_doc) nothrow @system {
		if (!_p_comment_buf) {
			return false;
		}
		return _write4(_p_comment_buf, p_doc);
	}

	bool Name_r(ref pxtnDescriptor p_doc) nothrow @system {
		return _read4_malloc(&_p_name_buf, &_name_size, p_doc);
	}

	bool Name_w(ref pxtnDescriptor p_doc) nothrow @system {
		if (!_p_name_buf) {
			return false;
		}
		return _write4(_p_name_buf, p_doc);
	}
}
