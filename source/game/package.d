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
import game.container;
import game.input;
import game.cursor;

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
        //this.CountFPS = true;
        this.ShowCursor = false;
    }

    override void LoadContent() {
        
        // Load content here with Content.Load!T
        // You can prefix the path in the Load function to load a raw file.
        setupManagers(Content);

        Input = new InputSystem();

        initMusicMgr();
        initTileRegistry();
        initItemRegistry();

        registerTileIOFor!Tile();
        registerContainerIO();
        registerChunkIO();

        Cursor = new GameCursorImpl();

        WORLD = new World();
        WORLD.init();

        font = Content.Load!SpriteFont("fonts/UIFont");
        msCounterPos = Vector2(font.MeasureString("XX ms").X, 4);
    }

    override void UnloadContent() {
        // Use the D function destroy(T) to unload content.
    }

    override void Update(GameTimes gameTime) {
        Input.beginInput();
        MusicManager.update();
        WORLD.update(gameTime);
        Input.endInput();
        Cursor.update();
    }

    override void Draw(GameTimes gameTime) {
        Renderer.ClearColor(Color.CornflowerBlue);
        WORLD.draw(sprite_batch);

        sprite_batch.Begin();

        Cursor.render(sprite_batch);


        // sprite_batch.DrawString(
        //     font, 
        //     "%dms".format(cast(int)gameTime.DeltaTime.Milliseconds*1000), 
        //     Vector2(Game.Window.ClientBounds.Width-msCounterPos.X, msCounterPos.Y), 
        //     Color.White, 
        //     1f);
        sprite_batch.End();
    }

    void save() {
        WORLD.save();
        //world.getLighting.stop();
    }
}