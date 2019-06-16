module game.lighting.smap;
import std.parallelism;
import game.world;
import game.chunk;
import polyplex;
import config;
import containers.list;

class ShadowMap(size_t WIDTH, size_t HEIGHT, size_t SCALE = CHUNK_SHADOW_SCALE) {
package(game.lighting):
    alias thisType = typeof(this);

    bool isLit;

    bool isUpdating;

    bool isFinished;

    float[WIDTH/SCALE][HEIGHT/SCALE] shadowMapData;
    float[WIDTH][HEIGHT] shadowMap;

    ubyte[(WIDTH*4)*HEIGHT] shadowMapTextureData;

    ubyte[(WIDTH*4)*HEIGHT] shadowMapTextureDataTMP;

    Texture2D shadowMapTexture;

    Color TRC;

    void genShadowMapFromData() {
        foreach(ix; 0..WIDTH/SCALE) {
            foreach(iy; 0..HEIGHT/SCALE) {
                static foreach(x; 0..SCALE) {
                    static foreach(y; 0..SCALE) {
                        shadowMap[(ix*SCALE)+x][(iy*SCALE)+y] = shadowMapData[ix][iy];
                    }
                }
            }
        }
    }

public:

    float getLight(Vector2i at) {
        return shadowMapData[at.X][at.Y];
    }

    void setLight(Vector2i at, float light) {
        isLit = true;
        shadowMapData[at.X][at.Y] = light;
    }

    this() {
        TRC = new Color(255, 255, 255, CHUNK_SHADOW_TRC);
        import polyplex.core.content.gl.textures;
        shadowMapTexture = new GlTexture2D(new TextureImg(CHUNK_SHADOW_SIZE, CHUNK_SHADOW_SIZE, this.shadowMapTextureData));
        clear(true);
    }

    void render(SpriteBatch spriteBatch, Rectangle area) {
        if (shadowMapTexture !is null) {
            if (area is null) return;
            float pxx = cast(float)shadowMapTexture.Width+(0.2f/cast(float)shadowMapTexture.Width);
            float pxy = cast(float)shadowMapTexture.Height+(0.2f/cast(float)shadowMapTexture.Height);
            spriteBatch.Draw(shadowMapTexture, area, new Rectangle(0, 0, cast(int)pxx, cast(int)pxy), TRC);
        }
    }

    bool busy() {
        return isUpdating && !isFinished;
    }

    void start() {
        isUpdating = true;
        isFinished = false;
    }

    /++
        Updates the texture and finishes the shadow mapping.
    +/
    void updateTexture() {
        if (isUpdating && isFinished) {
            this.shadowMapTextureData[] = this.shadowMapTextureDataTMP;
            shadowMapTexture.UpdatePixelData(this.shadowMapTextureData);
            finish();
        }
    }

    /++
        Mark changes as finished
    +/
    void finish() {
        if (isFinished) {
            isUpdating = false;
            isFinished = false;
        }
        isFinished = true;
    }

    bool lit() {
        return isLit;
    }

    /++
        Clears the shadowmap of data.
    +/
    void clear(bool fclear = false) {
        foreach(x; 0..WIDTH) {
            foreach(y; 0..HEIGHT) {
                shadowMap[x][y] = 0f;
            }
        }
        foreach(x; 0..WIDTH/SCALE) {
            foreach(y; 0..HEIGHT/SCALE) {
                shadowMapData[x][y] = 0f;
            }
        }
        if (fclear) {
            foreach(x; 0..(WIDTH*4)*HEIGHT) {
                shadowMapTextureData[x] = 0;
            }
        }
        isLit = false;
    }

}

class ShadowMapper(T) {
private:
    size_t nextUp;
    bool shouldStop;
    List!T[] toUpdate;
    Task!(shadowMapperTask, ShadowMapper, int)* shdMgrTask;

    int aliveMappers;

    /// Synchronized frontend for popFront.
    T popFront(int owner) {
        synchronized {
            return toUpdate[owner].popFront;
        }
    }

    void advanceNU() {
        synchronized {
            nextUp = (nextUp+1)%toUpdate.length;
        }
    }
public:

    void notifyUpdate(T shadow) {
        foreach(bucket; toUpdate) {
            if (bucket.contains(shadow)) return;
        }
        toUpdate[nextUp].add(shadow);
        advanceNU();
    }

    void start(int count = 4) {
        if (shdMgrTask is null) {
            toUpdate = new List!T[](count);
            shouldStop = false;
            foreach(i; 0..count) {
                aliveMappers++;
                taskPool.put(task!(shadowMapperTask, ShadowMapper!T, int)(this, i));
            }
        }
        if (shdMgrTask !is null && shdMgrTask.done()) {
            shdMgrTask = null;
        }
    }

    void stop() {
        shouldStop = true;
        while (aliveMappers > 0) {
            import core.thread : Thread;
            import std.datetime : Duration, msecs;
            Thread.sleep(50.msecs);
        }
    }
}

void shadowMapperTask(T)(ref ShadowMapper!T self, int id) {
    Logger.Success("Started ShadowMapper Task ({0})...", id);
    import core.thread : Thread;
    import std.datetime : Duration, msecs;
    int msgTimeout = 100;
    while(!self.shouldStop) {
        msgTimeout--;
        if (self.toUpdate[id].count > 0) {
            T shadowMap = self.popFront(id);
            // If it's busy, push it to the back for later...
            if (shadowMap.busy) self.notifyUpdate(shadowMap);

            // Otherwise, start mapping
            genShadowMapTex(shadowMap);

        
        } else Thread.sleep(50.msecs);
        if (msgTimeout <= 0) {
            Logger.Info("<ShadowMapper:{0}> Mapping (0 out of {1})...", id, self.toUpdate[id].count);
            msgTimeout = 100;
        }
    }
    Logger.Info("Stopped ShadowMapper Task... ({0})...", id);
    self.aliveMappers--;
}

/++
    Generate a shadow map texture from a chunk in a world.
+/
void genShadowMapTex(T)(T shmap) {
    shmap.start();

    // Generate the visual shadow map from the shadow map data.
    shmap.genShadowMapFromData();

    // Blur the shadowmap
    blurShadowMap(shmap.shadowMap, 4);

    // Set the texture data
    int ex = 0;
    foreach(x; 0..CHUNK_SHADOW_SIZE) {
        foreach(y; 0..CHUNK_SHADOW_SIZE) {
            shmap.shadowMapTextureDataTMP[ex] = 0;
            shmap.shadowMapTextureDataTMP[ex+1] = 0;
            shmap.shadowMapTextureDataTMP[ex+2] = 0;

            float val = Mathf.Min(shmap.shadowMap[y][x], 1f);
            shmap.shadowMapTextureDataTMP[ex+3] = cast(ubyte)((1f-val)*255);
            ex += 4;
        }
    }

    // Mark the map ready for rendering.
    shmap.finish();
}

/++
    Box-blur the specified shadowmap with the defined radius.
+/
void blurShadowMap(T)(ref T shadowMap, int r) {
    float[CHUNK_SHADOW_SIZE*CHUNK_SHADOW_SIZE] src;
    src[] = cast(float[])shadowMap;

    foreach(i; 0..CHUNK_SHADOW_SIZE) {
        foreach(j; 0..CHUNK_SHADOW_SIZE) {
            float val = 0;
            foreach(iy; i-r..i+r+1) {
                foreach(ix; j-r..j+r+1) {
                    size_t x = Mathf.Min(CHUNK_SHADOW_SIZE-1, Mathf.Max(0, ix));
                    size_t y = Mathf.Min(CHUNK_SHADOW_SIZE-1, Mathf.Max(0, iy));
                    val += src[y*CHUNK_SHADOW_SIZE+x];
                }
            }
            (cast(float[])shadowMap)[i*CHUNK_SHADOW_SIZE+j] = val/((r+r+1)*(r+r+1));
        }
    }
}