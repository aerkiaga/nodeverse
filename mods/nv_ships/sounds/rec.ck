// This is a ChucK program/patch
// It is based on the 'rec.ck' example from the official documentation
// (see https://chuck.cs.princeton.edu/doc/examples/basic/rec.ck
// or https://chuck.stanford.edu/doc/examples/basic/rec.ck)
// with an added feature to control duration
// by passing a 'duration' static variable inside a public 'Global' class

me.arg(0) => string filename;

// pull samples from the dac
dac => Gain g => WvOut w => blackhole;
// this is the output file name
filename => w.wavFilename;
<<<"(ChucK) writing to file:", "'" + w.filename() + "'">>>;
// any gain you want for the output
1 => g.gain;

// temporary workaround to automatically close file on remove-shred
null @=> w;

// time loop, will run for the specified duration
now + Global.duration => time end;
while( now < end ) 0.1::second => now;
