// actual sound definition
public class SoundDefinition {
    static dur duration;

    fun static polar sound_function(time t, float f) {
        return %(Math.random2f(0, 1), Math.random2f(0, 2*Math.PI));
    }
}

10::second => SoundDefinition.duration;
