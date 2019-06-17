module engine.cman;
import polyplex;

struct ContentCache(T) {
private:
    T[string] cachedItems;
    ContentManager content;

public:
    this(ContentManager content) {
        this.content = content;
    }

    ref T opIndex(string index) {
        if (index !in cachedItems) {
            this.add(index);
        }
        return cachedItems[index];
    }

    void add(string tex) {
        debug {
            cachedItems[tex] = content.Load!T("!raw/"~tex~".png");
        } else {
            cachedItems[tex] = content.Load!T(tex);
        }
    }

    void uncache(string tex) {
        cachedItems.remove(tex);
    }
}

__gshared static ContentCache!Texture2D TEXTURES;
__gshared static ContentCache!Music MUSIC;

void setupManagers(ContentManager mgr) {
    TEXTURES = ContentCache!Texture2D(mgr);
    MUSIC = ContentCache!Music(mgr);
}