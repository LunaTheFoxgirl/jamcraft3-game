module game.world;
import game.worldgen;
import game.chunk;
import game.entity;
import game.entities;
import game;
import game.utils;
import polyplex;
import containers.list;
import game.lighting.lman;
import msgpack;
import config;

class World {
private:
    WorldGenerator generator;
    Chunk[Vector2i] chunks;
    Entity player;
    Entity[] entities;
    LightingManager!ChunkShadowMap lighting;

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

    void updateChunks() {
        Vector2i playerChunk = player.chunkPosition();
        foreach(k, chunk; getChunks) {
            if (chunk.position.X < playerChunk.X-CHUNK_EXTENT_X ||
                chunk.position.X > playerChunk.X+CHUNK_EXTENT_X ||
                chunk.position.Y < playerChunk.Y-CHUNK_EXTENT_Y ||
                chunk.position.Y > playerChunk.Y+CHUNK_EXTENT_Y) {
                if (chunk.modified) {
                    // TODO: Save chunk if changed
                    chunk.save();
                }
                getChunks.remove(k);
            }
        }

        foreach(y; 0..CHUNK_EXTENT_Y*2) {
            foreach(x; 0..CHUNK_EXTENT_X*2) {
                Vector2i actualPosition = playerChunk+Vector2i(x-(CHUNK_EXTENT_X/2), y-(CHUNK_EXTENT_Y/2));

                if (actualPosition.X < playerChunk.X-(CHUNK_EXTENT_X/2)||
                    actualPosition.X > playerChunk.X+(CHUNK_EXTENT_X/2) ||
                    actualPosition.Y < playerChunk.Y-(CHUNK_EXTENT_Y/2) ||
                    actualPosition.Y > playerChunk.Y+(CHUNK_EXTENT_Y/2)) {
                        continue;
                    } 
                    
                if (this.hasChunkAt(actualPosition)) continue;
                getChunks[actualPosition] = loadChunk(actualPosition);
                lighting.notifyUpdate(actualPosition);
            }
        }
    }

    Chunk loadChunk(Vector2i position) {
        Chunk chnk = load(position, this);
        if (chnk !is null) return chnk;
        else return generator.generateChunk(position);
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

    this() {
        lighting = new LightingManager!ChunkShadowMap(this);
        lighting.start();
    }

    Player getPlayer() {
        return cast(Player)player;
    }

    ref LightingManager!ChunkShadowMap getLighting() {
        return lighting;
    }

    ref Chunk[Vector2i] getChunks() {
        return chunks;
    }

    Chunk opIndex(int x, int y) {
        Vector2i pos = Vector2i(x, y);
        if (pos in getChunks) return getChunks[pos];
        return null;
    }

    bool hasChunkAt(Vector2i pos) {
        return this[pos.X, pos.Y] !is null;
    }

    Tile tileAt(Vector2i position) {
        if (this is null) return null;
        Vector2i tilePos = position.wrapTilePos;
        Vector2i chunkPos = position.tilePosToChunkPos;
        if (this[chunkPos.X, chunkPos.Y] is null) return null;
        return this[chunkPos.X, chunkPos.Y].tiles[tilePos.X][tilePos.Y];
    }

    Tile wallAt(Vector2i position) {
        if (this is null) return null;
        Vector2i tilePos = position.wrapTilePos;
        Vector2i chunkPos = position.tilePosToChunkPos;
        if (this[chunkPos.X, chunkPos.Y] is null) return null;
        return this[chunkPos.X, chunkPos.Y].walls[tilePos.X][tilePos.Y];
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

    void invalidateLightArea(Vector2i chunkPos, int adjX, int adjY) {
        Vector2i[] adj = getAdjacent(chunkPos, adjX, adjY);
        foreach(chunk; adj) {
            lighting.notifyUpdate(chunk);
        }
    }

    void init() {
        generator = new WorldGenerator(this);
        camera = new Camera2D(Vector2(0f, 0f));
        camera.Zoom = 1.6f;

        player = new Player(this);
        updateChunks();
        loadWorld();
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
        updateChunks();
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
        spriteBatch.Begin(SpriteSorting.Deferred, Blending.NonPremultiplied, Sampling.LinearClamp, RasterizerState.Default, null, camera);
            foreach(chunk; getChunks) {
                chunk.drawShadowMap(spriteBatch);
            }
        spriteBatch.End();
    }

    void save() {
        foreach(_, chunk; getChunks) {
            if (chunk.modified) {
                // TODO: Save chunk if changed
                chunk.save();
            }
        }
        this.saveWorld();
    }
}

struct WorldSv {
    Vector2 playerPosition;
    float cameraZoom;
}