module game.world;
import game.worldgen;
import game.chunk;
import game.entity;
import game.entities;
import game;
import polyplex;
import containers.list;

enum CHUNK_EXTENT = 4;

class World {
private:
    WorldGenerator generator;
    List!Chunk chunks;
    Entity player;
    Entity[] entities;

    Rectangle effectiveViewport() {
        return new Rectangle(
            cast(int)((camera.Position.X)-(camera.Origin.X/camera.Zoom)),
            cast(int)((camera.Position.Y)-(camera.Origin.Y/camera.Zoom)),
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
                Logger.Info("Removed chunk at {0}", chunks[i].position);
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

public:
    Camera2D camera;

    this() {

    }

    void init() {
        generator = new WorldGenerator();
        camera = new Camera2D(Vector2(0f, 0f));

        player = new Player(this);
        updateChunks();
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
            
        spriteBatch.End();
    }

}