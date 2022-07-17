module pxtone.text;
// '12/03/03

import pxtone.descriptor;

bool _read4_malloc(char[]* pp, int* p_buf_size, ref pxtnDescriptor p_doc) @system {
	if (!pp) {
		return false;
	}
	p_doc.r(p_buf_size[0 .. 1]);
	if (*p_buf_size < 0) {
		return false;
	}

	bool b_ret = false;

	*pp = new char[](*p_buf_size + 1);
	if (!(*pp)) {
		return false;
	}

	(*pp)[0 .. *p_buf_size + 1] = 0;

	if (*p_buf_size) {
		p_doc.r((*pp)[0 .. *p_buf_size]);
	}

	b_ret = true;
term:
	if (!b_ret) {
		*pp = null;
	}

	return b_ret;
}

void _write4(const char[] p, ref pxtnDescriptor p_doc) @system {
	p_doc.w_asfile(cast(int)p.length);
	p_doc.w_asfile(p);
}

struct pxtnText {
private:
	char[] _p_comment_buf;
	int _comment_size;

	char[] _p_name_buf;
	int _name_size;

public:
	 ~this() nothrow @system {
		_p_comment_buf = null;
		_comment_size = 0;
		_p_name_buf = null;
		_name_size = 0;
	}

	bool set_comment_buf(const(char)* comment, int buf_size) nothrow @system {
		if (!comment) {
			return false;
		}
		_p_comment_buf = null;
		if (buf_size <= 0) {
			_comment_size = 0;
			return true;
		}
		_p_comment_buf = new char[](buf_size + 1);
		if (!(_p_comment_buf)) {
			return false;
		}
		_p_comment_buf[0 .. buf_size] = comment[0 .. buf_size];
		_p_comment_buf[buf_size] = '\0';
		_comment_size = buf_size;
		return true;
	}

	const(char)[] get_comment_buf() const nothrow @safe {
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
		_p_name_buf = null;
		if (buf_size <= 0) {
			_name_size = 0;
			return true;
		}
		_p_name_buf = new char[](buf_size + 1);
		if (!(_p_name_buf)) {
			return false;
		}
		_p_name_buf[0 .. buf_size] = name[0 .. buf_size];
		_p_name_buf[buf_size] = '\0';
		_name_size = buf_size;
		return true;
	}

	const(char)[] get_name_buf() const nothrow @safe {
		return _p_name_buf[0 .. _name_size];
	}

	bool is_name_buf() const nothrow @safe {
		if (_name_size > 0) {
			return true;
		}
		return false;
	}

	void Comment_r(ref pxtnDescriptor p_doc) @system {
		_read4_malloc(&_p_comment_buf, &_comment_size, p_doc);
	}

	bool Comment_w(ref pxtnDescriptor p_doc) @system {
		if (!_p_comment_buf) {
			return false;
		}
		_write4(_p_comment_buf, p_doc);
		return true;
	}

	void Name_r(ref pxtnDescriptor p_doc) @system {
		_read4_malloc(&_p_name_buf, &_name_size, p_doc);
	}

	bool Name_w(ref pxtnDescriptor p_doc) @system {
		if (!_p_name_buf) {
			return false;
		}
		_write4(_p_name_buf, p_doc);
		return true;
	}
}
