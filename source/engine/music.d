module engine.music;
import engine.cman;
import polyplex;
import containers.list;

private struct Track {
    Music track;
    float volume;
}

class MusicMgr {
private:
    Track*[string] tracks;
    string focusedTrack;

public:
    float gainSpeed = 0.01f;
    float maxGain = 0.4f;

    void addTrack(string name) {
        tracks[name] = new Track(MUSIC["music/mus_"~name], 0f);
        tracks[name].track.Play(true);
        tracks[name].track.Gain = tracks[name].volume;
    }

    void play(string name) {
        if (name !in tracks) return;
        if (focusedTrack == name) return;
        focusedTrack = name;
        Logger.Info("[MusicManager] Now playing {0}...", focusedTrack);
    }

    void update() {
        foreach(name, track; tracks) {
            if (name == focusedTrack) {
                track.volume += gainSpeed;
            } else {
                track.volume -= gainSpeed;
            }
            track.volume = Mathf.Max(Mathf.Min(track.volume, maxGain), 0f);
            track.track.Gain = track.volume;
        }
    }
}

__gshared MusicMgr MusicManager;

void initMusicMgr() {
    MusicManager = new MusicMgr();
    MusicManager.addTrack("day");
    MusicManager.addTrack("night");
    MusicManager.addTrack("underground");
}
