// This is a ChucK program/patch
// It is designed to be run along with another shred
// which must implement a public class named 'SoundDefinition'
// The 'duration' static field of the class is the duration of the sound
// The 'sound_function' static function gets a 'time' as first parameter and
// a 'float', representing frequency, as second, and must return a 'polar'
// with the intensity and phase of the sound at that time and frequency

// synthesize
IFFT ifft => dac;

// constants
(1::second / 1::samp) $ int => int sps;
1024 => int size;
sps $ float / size => float freq_coeff;

// spectrum buffer
complex s[size/2];

// run for specified duration
now + SoundDefinition.duration => time end;
while(now < end) {
    // populate frequencies
    for(0 => int n; n < size/2; n++) {
        n * freq_coeff => float frequency;
        SoundDefinition.sound_function(now, frequency) $ complex => s[n];
    }

    // take ifft
    ifft.transform(s);

    // advance time
    size::samp => now;
}
