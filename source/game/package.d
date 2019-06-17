module game;
import polyplex;
import engine.cman;
import game.tiles;
import game.items;
import game.tile;
import game.chunk;
import game.world;
import engine.music;
import std.format;

private __gshared static DunesGame gameImpl;

ref WindowBounds WINDOW_BOUNDS() {
    return gameImpl.Window.ClientBounds;
}

public class DunesGame : Game {
public:
    SpriteFont font;

    Vector2 msCounterPos;

    override void Init() {
        // Enable VSync
        Window.VSync = VSyncState.LateTearing;
        Window.AllowResizing = true;
        Window.Title = "Dunes";
        gameImpl = this;
        this.CountFPS = true;
    }

    override void LoadContent() {
        
        // Load content here with Content.Load!T
        // You can prefix the path in the Load function to load a raw file.
        setupManagers(Content);

        initMusicMgr();
        initTileRegistry();
        initItemRegistry();

        WORLD = new World();
        WORLD.init();


        registerTileIOFor!Tile();
        registerChunkIO();

        font = Content.Load!SpriteFont("fonts/UIFont");
        msCounterPos = Vector2(font.MeasureString("XX ms").X, 4);
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

        sprite_batch.Begin();

        sprite_batch.DrawString(
            font, 
            "%dms".format(cast(int)this.Frametime()), 
            Vector2(Game.Window.ClientBounds.Width-msCounterPos.X, msCounterPos.Y), 
            Color.White, 
            1f);
        sprite_batch.End();
    }

    void save() {
        WORLD.save();
        //world.getLighting.stop();
    }
}