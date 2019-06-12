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
        // if (position.Y == 1) {
        //     // TODO: Generate cave
        //     return GenerateFilled(position);
        // }

        enum H_HEIGHT_FACTOR = 8;
        enum H_HEIGHT_LIMIT = (CHUNK_SIZE*H_HEIGHT_FACTOR);
        enum H_SMOOTH_FACTOR = 120;

        Chunk chunk = new Chunk();
        chunk.position = position;
        chunk.loaded = true;
        chunk.modified = false;

        if (position.Y <= H_HEIGHT_FACTOR) {
            foreach(i; 0..CHUNK_SIZE) {
                double heightNoise = ngen.noise2D(
                    (cast(double)
                        (position.X*CHUNK_SIZE)/(H_SMOOTH_FACTOR/4))+
                        (cast(double)i/(H_SMOOTH_FACTOR/4)), 
                    245);

                int height = cast(int)((
                    ((ngen.noise2D(
                        (cast(double)
                            (position.X*CHUNK_SIZE)/H_SMOOTH_FACTOR)+
                            (cast(double)i/H_SMOOTH_FACTOR), 
                            1)*heightNoise))
                    ) * cast(float)H_HEIGHT_LIMIT);
                foreach(y; 0..CHUNK_SIZE) {
                    if ((position.Y*CHUNK_SIZE)+y >= height) {

                        double px = (cast(double)(position.X*CHUNK_SIZE)/10)+(cast(double)i/10);
                        double py = (cast(double)(position.Y*CHUNK_SIZE)/10)+(cast(double)y/10);

                        if (ngen.noise2D(px, py) > 0.5) {
                            chunk.walls[i][y] = new Block(Vector2i(i, y), "sand", chunk);
                        } else {
                            chunk.blocks[i][y] = new Block(Vector2i(i, y), "sand", chunk);
                            chunk.walls[i][y] = new Block(Vector2i(i, y), "sand", chunk);
                        }
                    }
                }
            }
        }

        if (position.Y > H_HEIGHT_FACTOR) {
            foreach(x; 0..CHUNK_SIZE) {
                foreach(y; 0..CHUNK_SIZE) {
                    double px = (cast(double)(position.X*CHUNK_SIZE)/10)+(cast(double)x/10);
                    double py = (cast(double)(position.Y*CHUNK_SIZE)/10)+(cast(double)y/10);
                    double px2 = (cast(double)(position.X*CHUNK_SIZE)/30)+(cast(double)x/30);
                    double py2 = (cast(double)(position.Y*CHUNK_SIZE)/30)+(cast(double)y/30);

                    if ((ngen.noise2D(px2, py2)*ngen.noise2D(px, py)) < 0.1 || ngen.noise2D(px2, py2) < 0.1) {
                        chunk.blocks[x][y] = new Block(Vector2i(x, y), "sand", chunk);
                    }
                    chunk.walls[x][y] = new Block(Vector2i(x, y), "sand", chunk);
                }
            }
        }
        return chunk;
    }
}