module pxtone.woiceptv;
// '12/03/03

import pxtone.pxtn;

import pxtone.descriptor;
import pxtone.error;
import pxtone.pulse.noise;
import pxtone.woice;

__gshared int _version = 20060111; // support no-envelope

void _Write_Wave(ref pxtnDescriptor p_doc, const(pxtnVOICEUNIT)* p_vc, ref int p_total) @system {
	int num, i, size;
	byte sc;
	ubyte uc;

	p_doc.v_w_asfile(p_vc.type, p_total);

	switch (p_vc.type) {
		// Coodinate (3)
	case pxtnVOICETYPE.Coodinate:
		p_doc.v_w_asfile(p_vc.wave.num, p_total);
		p_doc.v_w_asfile(p_vc.wave.reso, p_total);
		num = p_vc.wave.num;
		for (i = 0; i < num; i++) {
			uc = cast(byte) p_vc.wave.points[i].x;
			p_doc.w_asfile(uc);
			p_total++;
			sc = cast(byte) p_vc.wave.points[i].y;
			p_doc.w_asfile(sc);
			p_total++;
		}
		break;

		// Overtone (2)
	case pxtnVOICETYPE.Overtone:

		p_doc.v_w_asfile(p_vc.wave.num, p_total);
		num = p_vc.wave.num;
		for (i = 0; i < num; i++) {
			p_doc.v_w_asfile(p_vc.wave.points[i].x, p_total);
			p_doc.v_w_asfile(p_vc.wave.points[i].y, p_total);
		}
		break;

		// sampling (7)
	case pxtnVOICETYPE.Sampling:
		p_doc.v_w_asfile(p_vc.p_pcm.get_ch(), p_total);
		p_doc.v_w_asfile(p_vc.p_pcm.get_bps(), p_total);
		p_doc.v_w_asfile(p_vc.p_pcm.get_sps(), p_total);
		p_doc.v_w_asfile(p_vc.p_pcm.get_smp_head(), p_total);
		p_doc.v_w_asfile(p_vc.p_pcm.get_smp_body(), p_total);
		p_doc.v_w_asfile(p_vc.p_pcm.get_smp_tail(), p_total);

		size = p_vc.p_pcm.get_buf_size();

		p_doc.w_asfile(p_vc.p_pcm.get_p_buf());
		p_total += size;
		break;

	case pxtnVOICETYPE.OggVorbis:
		throw new PxtoneException("Ogg Vorbis is not supported here");
	default:
		break;
	}
}

void _Write_Envelope(ref pxtnDescriptor p_doc, const(pxtnVOICEUNIT)* p_vc, ref int p_total) @system {
	int num, i;

	// envelope. (5)
	p_doc.v_w_asfile(p_vc.envelope.fps, p_total);
	p_doc.v_w_asfile(p_vc.envelope.head_num, p_total);
	p_doc.v_w_asfile(p_vc.envelope.body_num, p_total);
	p_doc.v_w_asfile(p_vc.envelope.tail_num, p_total);

	num = p_vc.envelope.head_num + p_vc.envelope.body_num + p_vc.envelope.tail_num;
	for (i = 0; i < num; i++) {
		p_doc.v_w_asfile(p_vc.envelope.points[i].x, p_total);
		p_doc.v_w_asfile(p_vc.envelope.points[i].y, p_total);
	}
}

void _Read_Wave(ref pxtnDescriptor p_doc, pxtnVOICEUNIT* p_vc) @system {
	int i, num;
	byte sc;
	ubyte uc;

	p_doc.v_r(*cast(int*)&p_vc.type);

	switch (p_vc.type) {
		// coodinate (3)
	case pxtnVOICETYPE.Coodinate:
		p_doc.v_r(p_vc.wave.num);
		p_doc.v_r(p_vc.wave.reso);
		num = p_vc.wave.num;
		p_vc.wave.points = new pxtnPOINT[](num);
		if (!p_vc.wave.points) {
			throw new PxtoneException("Wave point buffer allocation failed");
		}
		for (i = 0; i < num; i++) {
			p_doc.r(uc);
			p_vc.wave.points[i].x = uc;
			p_doc.r(sc);
			p_vc.wave.points[i].y = sc;
		}
		num = p_vc.wave.num;
		break;
		// overtone (2)
	case pxtnVOICETYPE.Overtone:

		p_doc.v_r(p_vc.wave.num);
		num = p_vc.wave.num;
		p_vc.wave.points = new pxtnPOINT[](num);
		if (!p_vc.wave.points) {
			throw new PxtoneException("Wave point buffer allocation failed");
		}
		for (i = 0; i < num; i++) {
			p_doc.v_r(p_vc.wave.points[i].x);
			p_doc.v_r(p_vc.wave.points[i].y);
		}
		break;

		// p_vc.sampring. (7)
	case pxtnVOICETYPE.Sampling:
		throw new PxtoneException("fmt unknown"); // un-support

		//p_doc.v_r(p_vc.pcm.ch);
		//p_doc.v_r(p_vc.pcm.bps);
		//p_doc.v_r(p_vc.pcm.sps);
		//p_doc.v_r(p_vc.pcm.smp_head);
		//p_doc.v_r(p_vc.pcm.smp_body);
		//p_doc.v_r(p_vc.pcm.smp_tail);
		//size = ( p_vc.pcm.smp_head + p_vc.pcm.smp_body + p_vc.pcm.smp_tail ) * p_vc.pcm.ch * p_vc.pcm.bps / 8;
		//if( !_malloc_zero( (void **)&p_vc.pcm.p_smp,    size )          ) goto End;
		//if( !p_doc.r(        p_vc.pcm.p_smp, 1, size ) ) goto End;
		//break;

	default:
		throw new PxtoneException("PTV not supported"); // un-support
	}
}

void _Read_Envelope(ref pxtnDescriptor p_doc, pxtnVOICEUNIT* p_vc) @system {
	int num, i;

	scope(failure) {
		p_vc.envelope.points = null;
	}
	//p_vc.envelope. (5)
	p_doc.v_r(p_vc.envelope.fps);
	p_doc.v_r(p_vc.envelope.head_num);
	p_doc.v_r(p_vc.envelope.body_num);
	p_doc.v_r(p_vc.envelope.tail_num);
	if (p_vc.envelope.body_num) {
		throw new PxtoneException("fmt unknown");
	}
	if (p_vc.envelope.tail_num != 1) {
		throw new PxtoneException("fmt unknown");
	}

	num = p_vc.envelope.head_num + p_vc.envelope.body_num + p_vc.envelope.tail_num;
	p_vc.envelope.points = new pxtnPOINT[](num);
	if (!p_vc.envelope.points) {
		throw new PxtoneException("Envelope point buffer allocation failed");
	}
	for (i = 0; i < num; i++) {
		p_doc.v_r(p_vc.envelope.points[i].x);
		p_doc.v_r(p_vc.envelope.points[i].y);
	}
}
