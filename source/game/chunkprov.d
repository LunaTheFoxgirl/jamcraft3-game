module game.chunkprov;
import game.chunk;
import game.lighting.smap;
//import game.lighting.lman;
import game.worldgen;
import game.tile;
import game.world;
import game.utils;
import polyplex;
import config;
import core.sync.mutex;
import core.thread : Fiber;
import game.tiles;

class ChunkProvider {
private:
    alias cProvAlias = ShadowMap!(CHUNK_SIZE*CHUNK_EXTENT_X, CHUNK_SIZE*CHUNK_EXTENT_Y);
    World world;

    // Chunks
    Chunk[Vector2i] chunks;
    WorldGenerator generator;

    // Lighting
    //LightingManager!cProvAlias lighting;
    cProvAlias shadowMap;

    // Info
    Vector2i topCorner;

    // Threading
    Mutex chunkMutex;

    void updateChunks() {
        if (world.getPlayer is null) return;
        Vector2i playerChunk = world.getPlayer.chunkPosition();
        foreach(k, chunk; getChunks) {
            if (chunk.position.X < playerChunk.X-CHUNK_EXTENT_X ||
                chunk.position.X > playerChunk.X+CHUNK_EXTENT_X ||
                chunk.position.Y < playerChunk.Y-CHUNK_EXTENT_Y ||
                chunk.position.Y > playerChunk.Y+CHUNK_EXTENT_Y) {
                if (chunk.modified) {
                    // TODO: Save chunk if changed
                    chunk.save();
                }
                Logger.Info("Removing chunk @ {0}", k);
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
                Logger.Info("Adding chunk @ {0}", actualPosition);
                //lighting.notifyUpdate(actualPosition);
            }
        }
    }

    Fiber chunkProviderFiber;
    bool shouldStop;


public:
    this(World world) {
        this.world = world;
        generator = new WorldGenerator(world);
        //lighting = new LightingManager!cProvAlias(world);
        chunkMutex = new Mutex();
        //lighting.start();
        chunkProviderFiber = new Fiber(() {
            import core.thread : Thread;
            import std.datetime : Duration, msecs;
            initRegistry(false);
            while(!shouldStop) {
                try {
                    updateChunks();
                } catch(Exception ex) {
                    Logger.Warn(ex.msg);
                }
                Fiber.yield();
            }
        });
    }

    Chunk loadChunk(Vector2i position) {
        Chunk chnk = load(position, world);
        if (chnk !is null) return chnk;
        else return generator.generateChunk(position);
    }

    ref Chunk[Vector2i] getChunksSafe() {
        scope(exit) chunkMutex.unlock();
        chunkMutex.lock();
        return chunks;
    }

    ref Chunk[Vector2i] getChunks() {
        return chunks;
    }

    Chunk opIndex(int x, int y) {
        // scope(exit) chunkMutex.unlock();
        // chunkMutex.lock();
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

    void save() {
        foreach(_, chunk; getChunks) {
            if (chunk.modified) {
                // TODO: Save chunk if changed
                chunk.save();
            }
        }
    }

    void stop() {
        shouldStop = true;
    }

    // void start() {
    //     shouldStop = false;
    //     if (chunkProviderTask is null) {
    //         updateChunks();
    //         chunkProviderTask = task!(chunkProviderCallback)(this);
    //         chunkProviderTask.executeInNewThread();
    //     }
    // }

    void opCall() {
        chunkProviderFiber.call();
    }
}