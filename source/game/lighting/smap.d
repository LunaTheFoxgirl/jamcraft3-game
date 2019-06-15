module game.lighting.smap;
import std.parallelism;
import game.world;
import game.chunk;
import polyplex;
import config;


class ShadowMap(size_t WIDTH, size_t HEIGHT, size_t SCALE = CHUNK_SHADOW_SCALE) {
package(game.lighting):
    alias thisType = typeof(this);

    bool isLit;

    bool isShadowMappingRunning;

    Task!(genShadowMapTex, thisType)* shadowMapTask;

    float[WIDTH][HEIGHT] shadowMap;

    ubyte[(WIDTH*4)*HEIGHT] shadowMapTextureData;

    Texture2D shadowMapTexture;

    Color TRC;
public:

    float getLight(Vector2i at) {
        return shadowMap[at.X*SCALE][at.Y*SCALE];
    }

    void setLight(Vector2i at, float light) {
        isLit = true;
        static foreach(x; 0..SCALE) {
            static foreach(y; 0..SCALE) {
               shadowMap[(at.X*SCALE)+x][(at.Y*SCALE)+y] = light;
            }
        }
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

    /++
        Starts generating the shadow mapping
    +/
    void generate() {
        shadowMapTask = task!genShadowMapTex(this);
        taskPool.put(shadowMapTask);
    }

    /++
        Updates the texture and finishes the shadow mapping.
    +/
    void updateTexture() {
        if (done) {
            shadowMapTexture.UpdatePixelData(this.shadowMapTextureData);
            finish();
        }
    }

    bool lit() {
        return isLit;
    }

    /++
        Finishes off the shadowmap generation by disposing of the task.
    +/
    void finish() {
        shadowMapTask = null;
    }

    /++
        Returns true if the shadowmap is done generating
    +/
    bool done() {
        return (shadowMapTask !is null && shadowMapTask.done() && !isShadowMappingRunning);
    }

    /++
        Returns true if the shadowmap is busy being generated
    +/
    bool busy() {
        return (shadowMapTask !is null && (!shadowMapTask.done() || isShadowMappingRunning));
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
        if (fclear) {
            foreach(x; 0..(WIDTH*4)*HEIGHT) {
                shadowMapTextureData[x] = 0;
            }
        }
        isLit = false;
    }

}

/++
    Generate a shadow map texture from a chunk in a world.
+/
void genShadowMapTex(T)(ref T shmap) {
    shmap.isShadowMappingRunning = true;

    /// Blur the shadowmap
    blurShadowMap(shmap.shadowMap, 4);

    /// Set the texture data
    int ex = 0;
    foreach(x; 0..CHUNK_SHADOW_SIZE) {
        foreach(y; 0..CHUNK_SHADOW_SIZE) {
            shmap.shadowMapTextureData[ex] = 0;
            shmap.shadowMapTextureData[ex+1] = 0;
            shmap.shadowMapTextureData[ex+2] = 0;
            shmap.shadowMapTextureData[ex+3] = cast(ubyte)((1f-shmap.shadowMap[y][x])*255);
            ex += 4;
        }
    }

    // Mark the map ready for rendering.
    shmap.isShadowMappingRunning = false;
}

/++
    Box-blur the specified shadowmap with the defined radius.
+/
void blurShadowMap(ref float[CHUNK_SHADOW_SIZE][CHUNK_SHADOW_SIZE] shadowMap, int r) {
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