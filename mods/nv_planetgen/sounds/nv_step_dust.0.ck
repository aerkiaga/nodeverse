// The muffled sound of a rocket engine
// Has a peak at 200 Hz and low- and mid-frequency noise

// communication
public class Global {
    static dur duration;
}

0.3::second => Global.duration;

// patch
Noise noise => LPF low => HPF high => Envelope env => dac;

// parameters
1500 => low.freq;
500 => high.freq;
0.07::second => env.duration;
env.keyOn();

// control loop
now + Global.duration => time end;
true => int env_key;
while(now < end) {
    0.1::second => now;
    if(end - now < 0.25::second & env_key) {
        false => env_key;
        0.25::second => env.duration;
        env.keyOff();
    }
}
