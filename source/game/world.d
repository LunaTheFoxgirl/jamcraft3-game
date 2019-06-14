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

enum CHUNK_EXTENT = 5;

class World {
private:
    WorldGenerator generator;
    List!Chunk chunks;
    Entity player;
    Entity[] entities;

    Rectangle effectiveViewport() {
        
        return new Rectangle(
            cast(int)((camera.Position.X)-(camera.Origin.X/camera.Zoom)),//-(camera.Origin.X/camera.Zoom)),
            cast(int)((camera.Position.Y)-(camera.Origin.Y/camera.Zoom)),//-(camera.Origin.Y/camera.Zoom)),
            cast(int)(cast(float)WINDOW_BOUNDS.Width/camera.Zoom),
            cast(int)(cast(float)WINDOW_BOUNDS.Height/camera.Zoom)
        );
    }

    void updateChunks() {
        foreach(i; 0..chunks.count) {
            if (chunks[i].position.Distance(player.chunkPosition) > 8) {
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
                //Logger.Info("Removed chunk at {0}", chunks[i].position);
                chunks.removeAt(i);
            }
        }

        foreach(y; 0..CHUNK_EXTENT*2) {
            mfr: foreach(x; 0..CHUNK_EXTENT*2) {
                Vector2i actualPosition = player.chunkPosition()+Vector2i(x-(CHUNK_EXTENT/2)-2, y-(CHUNK_EXTENT/2));
                
                foreach(chunk; chunks) { 
                    if (chunk.position == actualPosition) continue mfr;
                }

                chunks ~= loadChunk(actualPosition);
            }
        }
    }

    Chunk loadChunk(Vector2i position) {
        Chunk chnk = load(position);
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
    }

    void saveWorld() {
    import std.file;
        import std.path;

        WorldSv saveInfo;
        saveInfo.playerPosition = Vector2(Mathf.Floor(player.position.X), Mathf.Floor(player.position.Y)-4f);

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
        Vector2i sTilePos = Vector2i(cast(int)camera.Position.X-cast(int)camera.Origin.X, cast(int)camera.Position.Y-cast(int)camera.Origin.Y);
        Vector2 mTilePos = mousePosition;
        Vector2i tilePos = Vector2i(sTilePos.X+cast(int)mTilePos.X, sTilePos.Y+cast(int)mTilePos.Y);
        return tilePos.toTilePos;
    }

    void init() {
        generator = new WorldGenerator();
        camera = new Camera2D(Vector2(0f, 0f));

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

            Rectangle eff = effectiveViewport;
            foreach(chunk; chunks) {
                chunk.drawWalls(spriteBatch, eff);
            }

            player.draw(spriteBatch);

            foreach(entity; entities) {
                entity.draw(spriteBatch);
            }

            foreach(chunk; chunks) {
                chunk.draw(spriteBatch, eff);
            }

            foreach(entity; entities) {
                entity.drawAfter(spriteBatch);
            }

            player.drawAfter(spriteBatch);
            
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
}