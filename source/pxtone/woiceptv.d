module pxtone.woiceptv;
// '12/03/03

import pxtone.pxtn;

import pxtone.descriptor;
import pxtone.error;
import pxtone.pulse.noise;
import pxtone.mem;
import pxtone.woice;

__gshared int _version = 20060111; // support no-envelope

bool _Write_Wave(pxtnDescriptor* p_doc, const(pxtnVOICEUNIT)* p_vc, int* p_total) nothrow @system {
	bool b_ret = false;
	int num, i, size;
	byte sc;
	ubyte uc;

	if (!p_doc.v_w_asfile(p_vc.type, p_total)) {
		goto End;
	}

	switch (p_vc.type) {
		// Coodinate (3)
	case pxtnVOICETYPE.pxtnVOICE_Coodinate:
		if (!p_doc.v_w_asfile(p_vc.wave.num, p_total)) {
			goto End;
		}
		if (!p_doc.v_w_asfile(p_vc.wave.reso, p_total)) {
			goto End;
		}
		num = p_vc.wave.num;
		for (i = 0; i < num; i++) {
			uc = cast(byte) p_vc.wave.points[i].x;
			if (!p_doc.w_asfile(&uc, 1, 1)) {
				goto End;
			}
			(*p_total)++;
			sc = cast(byte) p_vc.wave.points[i].y;
			if (!p_doc.w_asfile(&sc, 1, 1)) {
				goto End;
			}
			(*p_total)++;
		}
		break;

		// Overtone (2)
	case pxtnVOICETYPE.pxtnVOICE_Overtone:

		if (!p_doc.v_w_asfile(p_vc.wave.num, p_total)) {
			goto End;
		}
		num = p_vc.wave.num;
		for (i = 0; i < num; i++) {
			if (!p_doc.v_w_asfile(p_vc.wave.points[i].x, p_total)) {
				goto End;
			}
			if (!p_doc.v_w_asfile(p_vc.wave.points[i].y, p_total)) {
				goto End;
			}
		}
		break;

		// sampling (7)
	case pxtnVOICETYPE.pxtnVOICE_Sampling:
		if (!p_doc.v_w_asfile(p_vc.p_pcm.get_ch(), p_total)) {
			goto End;
		}
		if (!p_doc.v_w_asfile(p_vc.p_pcm.get_bps(), p_total)) {
			goto End;
		}
		if (!p_doc.v_w_asfile(p_vc.p_pcm.get_sps(), p_total)) {
			goto End;
		}
		if (!p_doc.v_w_asfile(p_vc.p_pcm.get_smp_head(), p_total)) {
			goto End;
		}
		if (!p_doc.v_w_asfile(p_vc.p_pcm.get_smp_body(), p_total)) {
			goto End;
		}
		if (!p_doc.v_w_asfile(p_vc.p_pcm.get_smp_tail(), p_total)) {
			goto End;
		}

		size = p_vc.p_pcm.get_buf_size();

		if (!p_doc.w_asfile(p_vc.p_pcm.get_p_buf().ptr, 1, size)) {
			goto End;
		}
		*p_total += size;
		break;

	case pxtnVOICETYPE.pxtnVOICE_OggVorbis:
		goto End; // not support.
	default:
		break;
	}

	b_ret = true;
End:

	return b_ret;
}

bool _Write_Envelope(pxtnDescriptor* p_doc, const(pxtnVOICEUNIT)* p_vc, int* p_total) nothrow @system {
	bool b_ret = false;
	int num, i;

	// envelope. (5)
	if (!p_doc.v_w_asfile(p_vc.envelope.fps, p_total)) {
		goto End;
	}
	if (!p_doc.v_w_asfile(p_vc.envelope.head_num, p_total)) {
		goto End;
	}
	if (!p_doc.v_w_asfile(p_vc.envelope.body_num, p_total)) {
		goto End;
	}
	if (!p_doc.v_w_asfile(p_vc.envelope.tail_num, p_total)) {
		goto End;
	}

	num = p_vc.envelope.head_num + p_vc.envelope.body_num + p_vc.envelope.tail_num;
	for (i = 0; i < num; i++) {
		if (!p_doc.v_w_asfile(p_vc.envelope.points[i].x, p_total)) {
			goto End;
		}
		if (!p_doc.v_w_asfile(p_vc.envelope.points[i].y, p_total)) {
			goto End;
		}
	}

	b_ret = true;
End:

	return b_ret;
}

pxtnERR _Read_Wave(pxtnDescriptor* p_doc, pxtnVOICEUNIT* p_vc) nothrow @system {
	int i, num;
	byte sc;
	ubyte uc;

	if (!p_doc.v_r(cast(int*)&p_vc.type)) {
		return pxtnERR.pxtnERR_desc_r;
	}

	switch (p_vc.type) {
		// coodinate (3)
	case pxtnVOICETYPE.pxtnVOICE_Coodinate:
		if (!p_doc.v_r(&p_vc.wave.num)) {
			return pxtnERR.pxtnERR_desc_r;
		}
		if (!p_doc.v_r(&p_vc.wave.reso)) {
			return pxtnERR.pxtnERR_desc_r;
		}
		num = p_vc.wave.num;
		p_vc.wave.points = allocate!pxtnPOINT(num);
		if (!p_vc.wave.points) {
			return pxtnERR.pxtnERR_memory;
		}
		for (i = 0; i < num; i++) {
			if (!p_doc.r(&uc, 1, 1)) {
				return pxtnERR.pxtnERR_desc_r;
			}
			p_vc.wave.points[i].x = uc;
			if (!p_doc.r(&sc, 1, 1)) {
				return pxtnERR.pxtnERR_desc_r;
			}
			p_vc.wave.points[i].y = sc;
		}
		num = p_vc.wave.num;
		break;
		// overtone (2)
	case pxtnVOICETYPE.pxtnVOICE_Overtone:

		if (!p_doc.v_r(&p_vc.wave.num)) {
			return pxtnERR.pxtnERR_desc_r;
		}
		num = p_vc.wave.num;
		p_vc.wave.points = allocate!pxtnPOINT(num);
		if (!p_vc.wave.points) {
			return pxtnERR.pxtnERR_memory;
		}
		for (i = 0; i < num; i++) {
			if (!p_doc.v_r(&p_vc.wave.points[i].x)) {
				return pxtnERR.pxtnERR_desc_r;
			}
			if (!p_doc.v_r(&p_vc.wave.points[i].y)) {
				return pxtnERR.pxtnERR_desc_r;
			}
		}
		break;

		// p_vc.sampring. (7)
	case pxtnVOICETYPE.pxtnVOICE_Sampling:
		return pxtnERR.pxtnERR_fmt_unknown; // un-support

		//if( !p_doc.v_r( &p_vc.pcm.ch       ) ) goto End;
		//if( !p_doc.v_r( &p_vc.pcm.bps      ) ) goto End;
		//if( !p_doc.v_r( &p_vc.pcm.sps      ) ) goto End;
		//if( !p_doc.v_r( &p_vc.pcm.smp_head ) ) goto End;
		//if( !p_doc.v_r( &p_vc.pcm.smp_body ) ) goto End;
		//if( !p_doc.v_r( &p_vc.pcm.smp_tail ) ) goto End;
		//size = ( p_vc.pcm.smp_head + p_vc.pcm.smp_body + p_vc.pcm.smp_tail ) * p_vc.pcm.ch * p_vc.pcm.bps / 8;
		//if( !_malloc_zero( (void **)&p_vc.pcm.p_smp,    size )          ) goto End;
		//if( !p_doc.r(        p_vc.pcm.p_smp, 1, size ) ) goto End;
		//break;

	default:
		return pxtnERR.pxtnERR_ptv_no_supported; // un-support
	}

	return pxtnERR.pxtnOK;
}

pxtnERR _Read_Envelope(pxtnDescriptor* p_doc, pxtnVOICEUNIT* p_vc) nothrow @system {
	pxtnERR res = pxtnERR.pxtnOK;
	int num, i;

	//p_vc.envelope. (5)
	if (!p_doc.v_r(&p_vc.envelope.fps)) {
		res = pxtnERR.pxtnERR_desc_r;
		goto term;
	}
	if (!p_doc.v_r(&p_vc.envelope.head_num)) {
		res = pxtnERR.pxtnERR_desc_r;
		goto term;
	}
	if (!p_doc.v_r(&p_vc.envelope.body_num)) {
		res = pxtnERR.pxtnERR_desc_r;
		goto term;
	}
	if (!p_doc.v_r(&p_vc.envelope.tail_num)) {
		res = pxtnERR.pxtnERR_desc_r;
		goto term;
	}
	if (p_vc.envelope.body_num) {
		res = pxtnERR.pxtnERR_fmt_unknown;
		goto term;
	}
	if (p_vc.envelope.tail_num != 1) {
		res = pxtnERR.pxtnERR_fmt_unknown;
		goto term;
	}

	num = p_vc.envelope.head_num + p_vc.envelope.body_num + p_vc.envelope.tail_num;
	p_vc.envelope.points = allocate!pxtnPOINT(num);
	if (!p_vc.envelope.points) {
		res = pxtnERR.pxtnERR_memory;
		goto term;
	}
	for (i = 0; i < num; i++) {
		if (!p_doc.v_r(&p_vc.envelope.points[i].x)) {
			res = pxtnERR.pxtnERR_desc_r;
			goto term;
		}
		if (!p_doc.v_r(&p_vc.envelope.points[i].y)) {
			res = pxtnERR.pxtnERR_desc_r;
			goto term;
		}
	}

	res = pxtnERR.pxtnOK;
term:
	if (res != pxtnERR.pxtnOK) {
		deallocate(p_vc.envelope.points);
	}

	return res;
}
