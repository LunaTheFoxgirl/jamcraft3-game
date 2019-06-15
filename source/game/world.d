module game.world;
import game.worldgen;
import game.chunk;
import game.entity;
import game.entities;
import game;
import game.utils;
import polyplex;
import containers.list;
import msgpack;
import config;

enum CHUNK_EXTENT_X = 6;
enum CHUNK_EXTENT_Y = 5;

class World {
private:
    WorldGenerator generator;
    List!Chunk chunks;
    Entity player;
    Entity[] entities;

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
        foreach(i; 0..chunks.count) {
            // if (chunks[i].position.Distance(player.chunkPosition) > 8) {
                // chunks[i].invalidated = true;
            // }
            if (chunks[i].position.X < playerChunk.X-CHUNK_EXTENT_X ||
                chunks[i].position.X > playerChunk.X+CHUNK_EXTENT_X ||
                chunks[i].position.Y < playerChunk.Y-CHUNK_EXTENT_Y ||
                chunks[i].position.Y > playerChunk.Y+CHUNK_EXTENT_Y) {
                    chunks[i].invalidated = true;
                }
        }

        foreach(i; 0..chunks.count) {
            if (i >= chunks.count) break;
            if (chunks[i].invalidated) {
                if (chunks[i].modified) {
                    // TODO: Save chunk if changed
                    chunks[i].save();
                }
                
                // if (chunks[i].isBusy()) {
                //     chunks[i].forceFinishLightingUpdate();
                // }
                chunks.removeAt(i);
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
                chunks ~= loadChunk(actualPosition);
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

    }

    Chunk opIndex(int x, int y) {
        foreach(chunk; chunks) {
            if (chunk.position.X == x && chunk.position.Y == y) return chunk;
        }
        return null;
    }

    bool hasChunkAt(Vector2i pos) {
        return this[pos.X, pos.Y] !is null;
    }

    Tile tileAt(Vector2i position) {
        Vector2i tilePos = position.wrapTilePos;
        Vector2i chunkPos = position.tilePosToChunkPos;
        if (this[chunkPos.X, chunkPos.Y] is null) return null;
        return this[chunkPos.X, chunkPos.Y].tiles[tilePos.X][tilePos.Y];
    }

    Tile wallAt(Vector2i position) {
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

    void init() {
        generator = new WorldGenerator(this);
        camera = new Camera2D(Vector2(0f, 0f));
        camera.Zoom = 1.6f;

        player = new Player(this);
        updateChunks();
        loadWorld();
    }

    void update(GameTimes gameTime) {
        foreach(chunk; chunks) {
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
            foreach(chunk; chunks) {
                if (chunk.getHitbox is null) continue;
                if (!chunk.getHitbox.Intersects(efView)) continue; 
                chunk.drawWalls(spriteBatch, efView);
            }

            player.draw(spriteBatch);

            foreach(entity; entities) {
                entity.draw(spriteBatch);
            }

            foreach(chunk; chunks) {
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
            foreach(chunk; chunks) {
                chunk.drawShadowMap(spriteBatch);
            }
        spriteBatch.End();
    }

    void save() {
        foreach(i; 0..chunks.count) {
            if (i >= chunks.count) break;
            if (chunks[i].modified) {
                // TODO: Save chunk if changed
                chunks[i].save();
            }
        }
        this.saveWorld();
    }
}

struct WorldSv {
    Vector2 playerPosition;
    float cameraZoom;
}