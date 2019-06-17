module game;
import polyplex;
import engine.cman;
import game.tiles;
import game.tile;
import game.chunk;
import game.world;
import engine.music;

private __gshared static DunesGame gameImpl;

ref WindowBounds WINDOW_BOUNDS() {
    return gameImpl.Window.ClientBounds;
}

public class DunesGame : Game {
public:
    override void Init() {
        // Enable VSync
        Window.VSync = VSyncState.LateTearing;
        Window.AllowResizing = true;
        Window.Title = "Dunes";
        gameImpl = this;
    }

    override void LoadContent() {
        // Load content here with Content.Load!T
        // You can prefix the path in the Load function to load a raw file.
        setupManagers(Content);

        initMusicMgr();

        registerTileIOFor!Tile();
        registerChunkIO();
        initTileRegistry();

        WORLD = new World();
        WORLD.init();
    }

    override void UnloadContent() {
        // Use the D function destroy(T) to unload content.
    }

    override void Update(GameTimes gameTime) {
        MusicManager.update();
        WORLD.update(gameTime);
    }

    override void Draw(GameTimes gameTime) {
        Renderer.ClearColor(Color.CornflowerBlue);
        WORLD.draw(sprite_batch);
    }

    void save() {
        WORLD.save();
        //world.getLighting.stop();
    }
}