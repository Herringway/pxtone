module pxtone.mem;

import core.stdc.stdlib;
import core.stdc.string;

bool pxtnMem_zero_alloc(void** pp, size_t byte_size) nothrow @system {
	*pp = malloc(byte_size);
	if (!(*pp)) {
		return false;
	}
	memset(*pp, 0, byte_size);
	return true;
}

bool pxtnMem_free(void** pp) nothrow @system {
	if (!pp || !*pp) {
		return false;
	}
	free(*pp);
	*pp = null;
	return true;
}

bool pxtnMem_zero(void* p, size_t byte_size) nothrow @system {
	(cast(ubyte*) p)[0 .. byte_size] = 0;
	return true;
}
