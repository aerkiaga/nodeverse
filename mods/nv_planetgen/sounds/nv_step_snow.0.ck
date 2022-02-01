// The sound of feet moving through snow (variant)
// Has a noise band from 300 - 2000 Hz and longer onset

// communication
public class Global {
    static dur duration;
}

0.4::second => Global.duration;

// patch
Noise noise => LPF low => HPF high => Envelope env => dac;

// parameters
2000 => low.freq;
300 => high.freq;
0.13::second => env.duration;
env.keyOn();

// control loop
now + Global.duration => time end;
true => int env_key;
while(now < end) {
    0.1::second => now;
    if(end - now < 0.2::second & env_key) {
        false => env_key;
        0.2::second => env.duration;
        env.keyOff();
    }
}
