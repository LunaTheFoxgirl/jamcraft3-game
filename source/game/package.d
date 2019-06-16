module game;
import polyplex;
import engine.cman;
import game.tiles;
import game.tile;
import game.chunk;
import game.world;

private __gshared static DunesGame gameImpl;

ref WindowBounds WINDOW_BOUNDS() {
    return gameImpl.Window.ClientBounds;
}

public class DunesGame : Game {
private:
    World world;

public:
    override void Init() {
        // Enable VSync
        Window.VSync = VSyncState.VSync;
        Window.AllowResizing = true;
        Window.Title = "Dunes";
        gameImpl = this;
    }

    override void LoadContent() {
        // Load content here with Content.Load!T
        // You can prefix the path in the Load function to load a raw file.
        setupManagers(Content);

        registerTileIOFor!Tile();
        registerChunkIO();
        initRegistry();

        world = new World();
        world.init();
    }

    override void UnloadContent() {
        // Use the D function destroy(T) to unload content.
    }

    override void Update(GameTimes gameTime) {
        world.update(gameTime);
    }

    override void Draw(GameTimes gameTime) {
        Renderer.ClearColor(Color.CornflowerBlue);
        world.draw(sprite_batch);
    }

    void save() {
        world.save();
        world.getLighting.stop();
    }
}