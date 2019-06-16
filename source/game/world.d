module game.world;
import game.worldgen;
import game.chunk;
import game.entity;
import game.entities;
import game;
import game.utils;
import game.chunkprov;
import polyplex;
import containers.list;
import msgpack;
import config;
import game.chunkprov;

class World {
private:
    Entity player;
    Entity[] entities;
    ChunkProvider provider;

    Rectangle effectiveViewport() {
        float px = (camera.Position.X-(camera.Origin.X/camera.Zoom));
        float py = (camera.Position.Y-(camera.Origin.Y/camera.Zoom));
        return new Rectangle(
            cast(int)(px),
            cast(int)(py),
            cast(int)(cast(float)WINDOW_BOUNDS.Width/camera.Zoom),
            cast(int)(cast(float)WINDOW_BOUNDS.Height/camera.Zoom)
        );
    }

    Rectangle effectiveViewportRenderbounds() {
        float px = (camera.Position.X-(camera.Origin.X/camera.Zoom));
        float py = (camera.Position.Y-(camera.Origin.Y/camera.Zoom));
        float ps = ((TILE_SIZE*2)*camera.Zoom)*2;
        return new Rectangle(
            cast(int)(px-ps),
            cast(int)(py-ps),
            cast(int)(cast(float)WINDOW_BOUNDS.Width/camera.Zoom)+cast(int)ps,
            cast(int)(cast(float)WINDOW_BOUNDS.Height/camera.Zoom)+cast(int)ps
        );
    }

    void loadWorld() {
        import std.file;
        import std.path;
        import std.format;
        string path = buildPath("world", "world.wld");
        if (!exists("world/")) mkdir("world/");
        if (!exists(path)) return;
        WorldSv ch = unpack!WorldSv(cast(ubyte[])read(path));
        
        player.position = ch.playerPosition;
        camera.Zoom = ch.cameraZoom;
    }

    void saveWorld() {
        import std.file;
        import std.path;

        WorldSv saveInfo;
        saveInfo.playerPosition = Vector2(Mathf.Floor(player.position.X), Mathf.Floor(player.position.Y)-4f);
        saveInfo.cameraZoom = camera.Zoom;

        if (!exists("world/")) mkdir("world/");
        write(buildPath("world", "world.wld"), pack(saveInfo));
    }

public:
    Camera2D camera;

    ref Chunk[Vector2i] getChunks() {
        return provider.getChunks;
    }

    Chunk opIndex(int x, int y) {
        return provider[x, y];
    }

    bool hasChunkAt(Vector2i pos) {
        return provider.hasChunkAt(pos);
    }

    Tile tileAt(Vector2i position) {
        return provider.tileAt(position);
    }

    Tile wallAt(Vector2i position) {
        return provider.wallAt(position);
    }


    Player getPlayer() {
        return cast(Player)player;
    }

    Vector2i getTileAtScreen(Vector2 mousePosition) {
        float px = (camera.Position.X-(camera.Origin.X/camera.Zoom));
        float py = (camera.Position.Y-(camera.Origin.Y/camera.Zoom));
        Vector2i sTilePos = Vector2i(cast(int)px, cast(int)py);
        Vector2 mTilePos = mousePosition/camera.Zoom;
        Vector2i tilePos = Vector2i(sTilePos.X+cast(int)mTilePos.X, sTilePos.Y+cast(int)mTilePos.Y);
        return tilePos.toTilePos;
    }

    bool isValidTile(Vector2i pos) {
        Vector2i chunkPos = pos.tilePosToChunkPos;
        if (this[chunkPos.X, chunkPos.Y] is null) return false;

        Vector2i tilePos = pos.wrapTilePos;
        if (this[chunkPos.X, chunkPos.Y].tiles[tilePos.X][tilePos.Y] !is null) return true;
        if (this[chunkPos.X, chunkPos.Y].walls[tilePos.X][tilePos.Y] !is null) return true;
        return false;
    }

    bool isValidTileInChunk(Vector2i pos) {
        Vector2i chunkPos = pos.tilePosToChunkPos;
        return this[chunkPos.X, chunkPos.Y] !is null;
    }

    // void invalidateLightArea(Vector2i chunkPos, int adjX, int adjY) {
    //     Vector2i[] adj = getAdjacent(chunkPos, adjX, adjY);
    //     foreach(chunk; adj) {
    //         lighting.notifyUpdate(chunk);
    //     }
    // }

    void init() {
        camera = new Camera2D(Vector2(0f, 0f));
        camera.Zoom = 1.6f;

        player = new Player(this);
        loadWorld();
        provider = new ChunkProvider(this);
    }

    void update(GameTimes gameTime) {
        foreach(chunk; getChunks) {
            chunk.update();
        }

        player.update(gameTime);

        foreach(entity; entities) {
            entity.update(gameTime);
        }

        camera.Origin = Vector2(WINDOW_BOUNDS.Width/2, WINDOW_BOUNDS.Height/2);
        provider();
    }

    void draw(SpriteBatch spriteBatch) {
        spriteBatch.Begin(SpriteSorting.Deferred, Blending.NonPremultiplied, Sampling.PointClamp, RasterizerState.Default, null, camera);

            Rectangle efView = effectiveViewportRenderbounds;
            foreach(chunk; getChunks) {
                if (chunk.getHitbox is null) continue;
                if (!chunk.getHitbox.Intersects(efView)) continue; 
                chunk.drawWalls(spriteBatch, efView);
            }

            player.draw(spriteBatch);

            foreach(entity; entities) {
                entity.draw(spriteBatch);
            }

            foreach(chunk; getChunks) {
                if (chunk.getHitbox is null) continue;
                if (!chunk.getHitbox.Intersects(efView)) continue; 
                chunk.draw(spriteBatch, efView);
            }


            foreach(entity; entities) {
                entity.drawAfter(spriteBatch);
            }

            player.drawAfter(spriteBatch);
        spriteBatch.End();
        // spriteBatch.Begin(SpriteSorting.Deferred, Blending.NonPremultiplied, Sampling.LinearClamp, RasterizerState.Default, null, camera);
        //     foreach(chunk; getChunks) {
        //         chunk.drawShadowMap(spriteBatch);
        //     }
        // spriteBatch.End();
    }

    void save() {
        provider.save();
        this.saveWorld();
    }
}

struct WorldSv {
    Vector2 playerPosition;
    float cameraZoom;
}