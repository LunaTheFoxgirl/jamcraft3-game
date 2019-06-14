module game.worldgen;
import dosimplex.generator;
import game.chunk;
import game.tiles;
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

        enum H_HEIGHT_FACTOR = 6;
        enum H_HEIGHT_LIMIT = (CHUNK_SIZE*H_HEIGHT_FACTOR);
        enum H_SMOOTH_FACTOR = 256;
        enum HARDSAND_START = 64;

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
                            if ((position.Y*CHUNK_SIZE)+y >= height+HARDSAND_START) {
                                chunk.walls[i][y] = new SandstoneTile(Vector2i(i, y), chunk);
                            } else {
                                chunk.walls[i][y] = new SandTile(Vector2i(i, y), chunk);
                            }
                        } else {
                            if ((position.Y*CHUNK_SIZE)+y >= height+HARDSAND_START) {
                                chunk.tiles[i][y] = new SandstoneTile(Vector2i(i, y), chunk);
                                chunk.walls[i][y] = new SandstoneTile(Vector2i(i, y), chunk);
                            } else {
                                chunk.tiles[i][y] = new SandTile(Vector2i(i, y), chunk);
                                chunk.walls[i][y] = new SandTile(Vector2i(i, y), chunk);
                            }
                        }
                    }
                }
            }
        }

        if (position.Y > H_HEIGHT_FACTOR) {
            foreach(x; 0..CHUNK_SIZE) {
                double heightNoise = ngen.noise2D(
                    (cast(double)
                        (position.X*CHUNK_SIZE)/(H_SMOOTH_FACTOR/4))+
                        (cast(double)x/(H_SMOOTH_FACTOR/4)), 
                    245);
                double ugHeightNoise = ngen.noise2D(
                    (cast(double)
                        (position.X*CHUNK_SIZE)/(H_SMOOTH_FACTOR/8))+
                        (cast(double)x/(H_SMOOTH_FACTOR/8)), 
                    245);

                int height = cast(int)((
                    ((ngen.noise2D(
                        (cast(double)
                            (position.X*CHUNK_SIZE)/H_SMOOTH_FACTOR)+
                            (cast(double)x/H_SMOOTH_FACTOR), 
                            1)*heightNoise*ugHeightNoise))
                    ) * cast(float)H_HEIGHT_LIMIT);

                foreach(y; 0..CHUNK_SIZE) {
                    double px = (cast(double)(position.X*CHUNK_SIZE)/10)+(cast(double)x/10);
                    double py = (cast(double)(position.Y*CHUNK_SIZE)/10)+(cast(double)y/10);
                    double px2 = (cast(double)(position.X*CHUNK_SIZE)/30)+(cast(double)x/30);
                    double py2 = (cast(double)(position.Y*CHUNK_SIZE)/30)+(cast(double)y/30);

                    if ((ngen.noise2D(px2, py2)*ngen.noise2D(px, py)) < 0.1 || ngen.noise2D(px2, py2) < 0.1) {
                        if ((position.Y*CHUNK_SIZE)+y >= height+HARDSAND_START) {
                            chunk.tiles[x][y] = new SandstoneTile(Vector2i(x, y), chunk);
                        } else {
                            chunk.tiles[x][y] = new SandTile(Vector2i(x, y), chunk);
                        }
                    }
                    if ((position.Y*CHUNK_SIZE)+y >= height+HARDSAND_START) {
                        chunk.walls[x][y] = new SandstoneTile(Vector2i(x, y), chunk);
                    } else {
                        chunk.walls[x][y] = new SandTile(Vector2i(x, y), chunk);
                    }
                }
            }
        }
        return chunk;
    }
}