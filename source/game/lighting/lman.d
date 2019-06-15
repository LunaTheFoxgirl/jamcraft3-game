module game.lighting.lman;
import game.lighting.smap;
import game.chunk;
import game.world;
import std.parallelism;
import polyplex;
import config;
import game.utils;
import containers.list;

class LightingManager {
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
        if (world[cAt.X, cAt.Y] is null) return 0f;
        return world[cAt.X, cAt.Y].shadowMap.getLight(lpAt);
    }

    void setLight(Vector2i at, float light) {
        Vector2i lpAt = at.wrapTilePos;
        Vector2i cAt = at.tilePosToChunkPos;
        
        if (world[cAt.X, cAt.Y] is null) return;

        world[cAt.X, cAt.Y].shadowMap.setLight(lpAt, light);
    }

    void applyLight(Vector2i current, float last) {
        if (!isValidPosition(current)) return;
        float newLight = last-getLightBlockingAt(current);
        if (newLight <= getLight(current)) return;

        setLight(current, newLight);

        applyLight(Vector2i(current.X+1, current.Y), newLight);
        applyLight(Vector2i(current.X, current.Y+1), newLight);
        applyLight(Vector2i(current.X-1, current.Y), newLight);
        applyLight(Vector2i(current.X, current.Y-1), newLight);
    }

    void runLightPass(Vector2i chunkPos, int lastSpread) {
        if (!world.hasChunkAt(chunkPos)) return;

        // Make sure we don't spread indefinately.
        int newSpread = lastSpread-1;
        if (newSpread <= 0 || newSpread > lastSpread) return;
        if (chunkPos in spread && spread[chunkPos] < newSpread) return;
        spread[chunkPos] = newSpread;
        
        // Run lighting passes on neighbours first!
        // runLightPass(Vector2i(chunkPos.X+1, chunkPos.Y),   newSpread);
        // runLightPass(Vector2i(chunkPos.X,   chunkPos.Y+1), newSpread);
        // runLightPass(Vector2i(chunkPos.X-1, chunkPos.Y),   newSpread);
        // runLightPass(Vector2i(chunkPos.X,   chunkPos.Y-1), newSpread);

        // Diagonals
        // runLightPass(Vector2i(chunkPos.X+1, chunkPos.Y-1), newSpread);
        // runLightPass(Vector2i(chunkPos.X+1, chunkPos.Y+1), newSpread);
        // runLightPass(Vector2i(chunkPos.X-1, chunkPos.Y+1), newSpread);
        // runLightPass(Vector2i(chunkPos.X-1, chunkPos.Y-1), newSpread);

        // Clear the current shadow map
        if (world.getChunks[chunkPos].shadowMap.lit) 
            world.getChunks[chunkPos].shadowMap.clear();

        /// Then run out lighting pass
        foreach(x; 0..CHUNK_SIZE) {
            foreach(y; 0..CHUNK_SIZE) {
                Vector2i wpos = (chunkPos.chunkPosToTilePos)+Vector2i(x, y);
                if (this.getLightData(wpos) > 0.0f) {
                    this.applyLight(wpos, this.getLightData(wpos));
                }
            }
        }
        
        //genShadowMapTex(world.getChunks[chunkPos].shadowMap);
        world.getChunks[chunkPos].shadowMap.generate();
        runLightPass(Vector2i(chunkPos.X+1, chunkPos.Y),   newSpread);
        runLightPass(Vector2i(chunkPos.X,   chunkPos.Y+1), newSpread);
        runLightPass(Vector2i(chunkPos.X-1, chunkPos.Y),   newSpread);
        runLightPass(Vector2i(chunkPos.X,   chunkPos.Y-1), newSpread);
    }

    int[Vector2i] spread;
    bool shouldStop;

    List!Vector2i toUpdate;
public:

    this (World world) {
        this.world = world;
    }

    void notifyUpdate(Vector2i pos) {
        toUpdate.add(pos);
    }

    void start(int spread = 4) {
        if (lightMgrTask is null) {
            shouldStop = false;
            taskPool.put(task!lightPass(world, this, spread));
        }
        if (lightMgrTask !is null && lightMgrTask.done()) {
            lightMgrTask = null;
        }
    }

    void stop() {
        shouldStop = true;
    }
}

void lightPass(ref World world, ref LightingManager self, int spread = 4) {
    import core.thread : Thread;
    import std.datetime : Duration, msecs;
    while(!shouldStop) {
        if (self.toUpdate.count > 0) {
            Vector2i chunkPos = self.toUpdate.popFront();
            //Logger.Info("Updating {0}... (0 out of {1})", chunkPos, self.toUpdate.count);
            
            self.spread.clear();
            self.runLightPass(chunkPos, spread);
        } else Thread.sleep(50.msecs);
    }
    Logger.Info("Stopped LightManager loop...");
}