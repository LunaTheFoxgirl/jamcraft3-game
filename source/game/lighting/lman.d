module game.lighting.lman;
import game.lighting.smap;
import game.chunk;
import game.world;
import std.parallelism;
import polyplex;
import config;
import game.utils;
import containers.list;

class LightingManager(T) {
private:
    World world;
    Task!(lightPass, World, LightingManager, int)* lightMgrTask;

    bool isValidPosition(Vector2i pos) {
        return (world.isValidTileInChunk(pos));
    }

    float getLightBlockingAt(Vector2i at) {
        if (world.tileAt(at) !is null) {
            return world.tileAt(at).getLightBlock();
        }
        return LIGHT_MIN_BLOCK;
    }

    float getLightData(Vector2i at) {
        if (world.wallAt(at) is null && world.tileAt(at) is null) return 1f;
        if (world.tileAt(at) !is null) return world.tileAt(at).getEmission();
        return 0f;
    }

    float getLight(Vector2i at) {
        Vector2i lpAt = at.wrapTilePos;
        Vector2i cAt = at.tilePosToChunkPos;
        if (world[cAt.X, cAt.Y] is null) return 1f;
        return world[cAt.X, cAt.Y].shadowMap.getLight(lpAt);
    }

    void setLight(Vector2i at, float light) {
        Vector2i lpAt = at.wrapTilePos;
        Vector2i cAt = at.tilePosToChunkPos;
        
        if (world[cAt.X, cAt.Y] is null) return;

        world[cAt.X, cAt.Y].shadowMap.setLight(lpAt, light);
    }

    void applyLight(Vector2i current, float last, bool doBlockLight = true) {
        if (!isValidPosition(current)) return;
        float newLight = last;
        if (doBlockLight) {
            newLight -= getLightBlockingAt(current);
            if (newLight <= getLight(current)) return;
        }

        setLight(current, newLight);

        applyLight(Vector2i(current.X+1, current.Y), newLight);
        applyLight(Vector2i(current.X, current.Y+1), newLight);
        applyLight(Vector2i(current.X-1, current.Y), newLight);
        applyLight(Vector2i(current.X, current.Y-1), newLight);
    }

    void applyLightSpread(Vector2i current, float last) {
        if (!isValidPosition(current)) return;

        applyLight(Vector2i(current.X+1, current.Y), last, true);
        applyLight(Vector2i(current.X, current.Y+1), last, true);
        applyLight(Vector2i(current.X-1, current.Y), last, true);
        applyLight(Vector2i(current.X, current.Y-1), last, true);

        applyLight(Vector2i(current.X+1, current.Y+1), last, true);
        applyLight(Vector2i(current.X-1, current.Y+1), last, true);
        applyLight(Vector2i(current.X-1, current.Y-1), last, true);
        applyLight(Vector2i(current.X+1, current.Y-1), last, true);
    }

    void applyPostLightpass(Vector2i wpos, Vector2i chunkPos) {
        if (this.getLightData(wpos) > 0.0f) {
            this.applyLightSpread(wpos, this.getLightData(wpos));
        } else {
            this.applyLightSpread(wpos, this.getLight(wpos));
        }
    }

    // Light pass that only propergates already existing light at edges of chunk
    void runPostLightPass(Vector2i chunkPos) {
        if (!world.hasChunkAt(chunkPos)) return;

        // Apply light bleeding
        foreach(x; 0..CHUNK_SIZE) {
            Vector2i wpos = (chunkPos.chunkPosToTilePos);
            applyPostLightpass(wpos+Vector2i(x,                    0), chunkPos);
            applyPostLightpass(wpos+Vector2i(x,         CHUNK_SIZE-1), chunkPos);
        }

        foreach(y; 0..CHUNK_SIZE) {
            Vector2i wpos = (chunkPos.chunkPosToTilePos);
            applyPostLightpass(wpos+Vector2i(0,            y), chunkPos);
            applyPostLightpass(wpos+Vector2i(CHUNK_SIZE-1, y), chunkPos);
        }
        updatedChunks ~= chunkPos;
    }

    void runLightPass(Vector2i chunkPos, bool root) {
        if (!world.hasChunkAt(chunkPos)) return;

        // Make sure we don't spread indefinately.
        // int newSpread = lastSpread-1;
        // if (newSpread <= 0) return;
        // if (chunkPos in spread && spread[chunkPos] >= newSpread) return;
        // spread[chunkPos] = newSpread;
        
        // Run lighting passes on neighbours first!


        /// Then run our lighting pass
        foreach(x; 0..CHUNK_SIZE) {
            foreach(y; 0..CHUNK_SIZE) {
                Vector2i wpos = (chunkPos.chunkPosToTilePos)+Vector2i(x, y);
                if (this.getLightData(wpos) > 0.0f) {
                    this.applyLight(wpos, this.getLightData(wpos));
                }
            }
        }

        if (root) {

            runPostLightPass(Vector2i(chunkPos.X+1, chunkPos.Y));
            runPostLightPass(Vector2i(chunkPos.X,   chunkPos.Y+1));
            runPostLightPass(Vector2i(chunkPos.X-1, chunkPos.Y));
            runPostLightPass(Vector2i(chunkPos.X,   chunkPos.Y-1));

            // Diagonals
            runPostLightPass(Vector2i(chunkPos.X+1, chunkPos.Y-1));
            runPostLightPass(Vector2i(chunkPos.X+1, chunkPos.Y+1));
            runPostLightPass(Vector2i(chunkPos.X-1, chunkPos.Y+1));
            runPostLightPass(Vector2i(chunkPos.X-1, chunkPos.Y-1));
            runPostLightPass(chunkPos);

            // Clear the current shadow map
            // if (world.getChunks[chunkPos].shadowMap.lit) 
                // world.getChunks[chunkPos].shadowMap.clear();
        }
    
        //genShadowMapTex(world.getChunks[chunkPos].shadowMap);
        mapper.notifyUpdate(world.getChunks[chunkPos].shadowMap);
    }

    void execLightpass(Vector2i chunkPos) {
        spread.clear();

        // Clear lighting
        if (world.getChunks[chunkPos].shadowMap.lit) 
            world.getChunks[chunkPos].shadowMap.clear();

        // Run light pass
        runLightPass(chunkPos, true);

        //Logger.Info("Done lighting, notifying update...");
        // Notify adjacent chunks to update their lighting texture.
        foreach(chunk; updatedChunks) {
            mapper.notifyUpdate(world.getChunks[chunk].shadowMap);
        }
    }

    int[Vector2i] spread;
    bool shouldStop;
    bool alive;

    List!Vector2i updatedChunks;

    List!Vector2i toUpdate;
    ShadowMapper!T mapper;
public:

    this (World world) {
        this.world = world;
        mapper = new ShadowMapper!T();
    }

    void notifyUpdate(Vector2i pos) {
        toUpdate.add(pos);
    }

    void start(int spread = 3) {
        if (lightMgrTask is null) {
            mapper.start();
            shouldStop = false;
            alive = true;
            taskPool.put(task!lightPass(world, this, spread));
        }
        if (lightMgrTask !is null && lightMgrTask.done()) {
            lightMgrTask = null;
        }
    }

    void stop() {
        shouldStop = true;
        mapper.stop();
        while (alive) {
            import core.thread : Thread;
            import std.datetime : Duration, msecs;
            Thread.sleep(50.msecs);
        }
    }
}

void lightPass(T)(ref World world, ref LightingManager!T self, int spread = 3) {
    Logger.Success("Started LightManager Task...");
    import core.thread : Thread;
    import std.datetime : Duration, msecs;
    int msgTimeout = 20;
    while(!self.shouldStop) {

        if (self.toUpdate.count > 0) {
            Vector2i chunkPos = self.toUpdate.popFront();
            self.execLightpass(chunkPos);
        } else Thread.sleep(50.msecs);



        debug {
            msgTimeout--;
            if (msgTimeout <= 0) {
                Logger.Info("<LightManager> Updating (0 out of {0})...", self.toUpdate.count);
                msgTimeout = 20;
            }
        }
    }
    Logger.Info("Stopped LightManager Task...");
    self.alive = false;
}