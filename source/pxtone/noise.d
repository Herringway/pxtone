module pxtone.noise;

// '12/03/29

import pxtone.descriptor;
import pxtone.mem;

import pxtone.pulse.noisebuilder;
import pxtone.pulse.noise;
import pxtone.pulse.pcm;
import pxtone.error;

struct pxtoneNoise {
	void* _bldr;
	int _ch_num = 2;
	int _sps = 44100;
	int _bps = 16;

	~this() nothrow @system {
		deallocate(_bldr);
	}

	bool init() nothrow @system {
		pxtnPulse_NoiseBuilder* bldr = allocate!pxtnPulse_NoiseBuilder();
		_bldr = cast(void*) bldr;
		return true;
	}

	bool quality_set(int ch_num, int sps, int bps) nothrow @safe {
		switch (ch_num) {
		case 1:
		case 2:
			break;
		default:
			return false;
		}

		switch (sps) {
		case 48000:
		case 44100:
		case 22050:
		case 11025:
			break;
		default:
			return false;
		}

		switch (bps) {
		case 8:
		case 16:
			break;
		default:
			return false;
		}

		_ch_num = ch_num;
		_bps = bps;
		_sps = sps;

		return false;
	}

	void quality_get(out int p_ch_num, out int p_sps, out int p_bps) const nothrow @safe {
		if (p_ch_num) {
			p_ch_num = _ch_num;
		}
		if (p_sps) {
			p_sps = _sps;
		}
		if (p_bps) {
			p_bps = _bps;
		}
	}

	bool generate(ref pxtnDescriptor p_doc, out void[] pp_buf, out int p_size) const nothrow @system {
		bool b_ret = false;
		pxtnPulse_NoiseBuilder* bldr = cast(pxtnPulse_NoiseBuilder*) _bldr;
		pxtnPulse_Noise* noise = allocate!pxtnPulse_Noise();
		pxtnPulse_PCM* pcm = null;

		if (noise.read(p_doc) != pxtnERR.OK) {
			goto End;
		}
		pcm = bldr.BuildNoise(noise, _ch_num, _sps, _bps);
		if (!(pcm)) {
			goto End;
		}

		p_size = pcm.get_buf_size();
		pp_buf = pcm.Devolve_SamplingBuffer();

		b_ret = true;
	End:
		deallocate(noise);
		deallocate(pcm);

		return b_ret;
	}
}
