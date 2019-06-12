module game;
import polyplex;
import engine.cman;
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
        Window.VSync = VSyncState.Immidiate;
        Window.AllowResizing = true;
        Window.Title = "Dunes";
        gameImpl = this;
    }

    override void LoadContent() {
        // Load content here with Content.Load!T
        // You can prefix the path in the Load function to load a raw file.
        setupManagers(Content);

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
        Renderer.ClearColor(Color.Black);
        world.draw(sprite_batch);
    }
}