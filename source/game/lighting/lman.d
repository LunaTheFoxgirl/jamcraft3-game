module game.lighting.lman;
import game.chunk;
import game.world;
import std.parallelism;
import polyplex;
import config;

class LightingManager {
private:
    World world;

    // bool isValidPosition(Vector2i pos) {
    //     return !(pos.X < -CHUNK_SIZE || pos.Y < -CHUNK_SIZE || pos.X >= CHUNK_SIZE*2 || pos.Y >= CHUNK_SIZE*2);
    //     //return isValidLocalPosition(pos);
    // }

    // bool isValidLocalPosition(Vector2i pos) {
    //     return !(pos.X < 0 || pos.Y < 0 || pos.X >= CHUNK_SIZE || pos.Y >= CHUNK_SIZE);
    // }

    // float getLightBlockingAt(Vector2i at) {
    //     Vector2i worldCoords = position.chunkPosToTilePos;
    //     Vector2i atWorld = worldCoords+at;

    //     if (world.hasChunkAt(atWorld.tilePosToChunkPos)) {
    //         if (world.tileAt(atWorld) !is null) return world.tileAt(atWorld).getLightBlock();
    //         return LIGHT_MIN_BLOCK;
    //     }

    //     //if (tiles[at.X][at.Y] !is null) return tiles[at.X][at.Y].getLightBlock();
    //     return LIGHT_MIN_BLOCK;
    // }

    // float getLightData(Vector2i at) {
    //     Vector2i worldCoords = position.chunkPosToTilePos;
    //     Vector2i atWorld = worldCoords+at;
    //     if (world.wallAt(atWorld) is null && world.tileAt(atWorld) is null) return 1f;
    //     if (world.tileAt(atWorld) !is null) return world.tileAt(atWorld).getEmission();
    //     return 0f;
    // }

    // float getLight(Vector2i at) {
    //     return shadowMap[at.X*CHUNK_SHADOW_SCALE][at.Y*CHUNK_SHADOW_SCALE];
    // }

    // void setLight(Vector2i at, float light) {
    //     static foreach(x; 0..CHUNK_SHADOW_SCALE) {
    //         static foreach(y; 0..CHUNK_SHADOW_SCALE) {
    //             shadowMap[(at.X*CHUNK_SHADOW_SCALE)+x][(at.Y*CHUNK_SHADOW_SCALE)+y] = light;
    //         }
    //     }
    // }

    // void applyLight(Vector2i current, float last) {
    //     if (!isValidPosition(current)) return;
    //     float newLight = last-getLightBlockingAt(current);
    //     if (newLight <= getLight(current)) return;


    //     setLight(current, newLight);

    //     applyLight(Vector2i(current.X+1, current.Y), newLight);
    //     applyLight(Vector2i(current.X, current.Y+1), newLight);
    //     applyLight(Vector2i(current.X-1, current.Y), newLight);
    //     applyLight(Vector2i(current.X, current.Y-1), newLight);
    // }

public:

    this (World world) {
        this.world = world;
    }

    void runLightingPass() {
        taskPool.put(task!lightPass(world, this));
    }

    /++
        Notify the world of a lighting change.

        This will regenerate the lighting for the world.
    +/
    void notifyWorldChange(Vector2i pos) {
        runLightingPass();
    }
}

void lightPass(ref World world, ref LightingManager self) {
    
}