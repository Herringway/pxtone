module pxtone.mem;

import core.stdc.stdint;
import core.stdc.stdlib;
import core.stdc.string;

bool pxtnMem_zero_alloc( void** pp, uint32_t byte_size )
{
	*pp = malloc( byte_size );
	if( !( *pp  ) ) return false;
	memset( *pp, 0,       byte_size );
	return true;
}

bool pxtnMem_free( void** pp )
{
	if( !pp || !*pp ) return false;
	free( *pp ); *pp = null;
	return true;
}

bool pxtnMem_zero( void*  p , uint32_t byte_size )
{
	(cast(ubyte*)p)[0 .. byte_size] = 0;
	return true;
}
