module pxtone.mem;

import std.experimental.allocator;

T* allocate(T)() {
	return theAllocator.make!T;
}

T[] allocate(T)(size_t count) {
	return theAllocator.makeArray!T(count);
}

void deallocate(T)(ref T[] array) nothrow @system {
	return theAllocator.dispose(array);
}
void deallocate(T)(ref T* ptr) nothrow @system {
	return theAllocator.dispose(ptr);
}
