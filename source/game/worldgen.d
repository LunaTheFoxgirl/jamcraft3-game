module game.worldgen;
import dosimplex.generator;
import game.chunk;
import game.block;
import polyplex;

class WorldGenerator {
private:
    SNoiseGenerator ngen;
public:
    this() {
        ngen = SNoiseGenerator(SNoiseGenerator.DEFAULT_SEED);
    }

    Chunk generateChunk(Vector2i position) {
        if (position.Y == 1) {
            // TODO: Generate cave
            return GenerateFilled(position);
        }

        if (position.Y > 1) {
            Chunk chunk = new Chunk();
            chunk.position = position;
            chunk.loaded = true;
            chunk.modified = false;
            foreach(x; 0..CHUNK_SIZE) {
                foreach(y; 0..CHUNK_SIZE) {
                    double px = (cast(double)(position.X*CHUNK_SIZE)/10)+(cast(double)x/10);
                    double py = (cast(double)(position.Y*CHUNK_SIZE)/10)+(cast(double)y/10);

                    if (ngen.noise2D(px, py) < 0.1) {
                        chunk.blocks[x][y] = new Block(Vector2i(x, y), "sand", chunk);
                    } else {
                        chunk.walls[x][y] = new Block(Vector2i(x, y), "sand", chunk);
                    }
                }
            }
            return chunk;
        }
        
        
        if (position.Y == 0) {
            Chunk chunk = new Chunk();
            chunk.position = position;
            chunk.loaded = true;
            chunk.modified = false;
            foreach(i; 0..CHUNK_SIZE) {
                int height = cast(int)(((ngen.noise2D((cast(double)(position.X*CHUNK_SIZE)/10)+(cast(double)i/10), 1)+1)/2)*CHUNK_SIZE);
                foreach(y; height..CHUNK_SIZE) {
                    chunk.blocks[i][y] = new Block(Vector2i(i, y), "sand", chunk);
                    chunk.walls[i][y] = new Block(Vector2i(i, y), "sand", chunk);
                }
            }
            return chunk;
        }
        
        return GenerateAir(position);
    }
}