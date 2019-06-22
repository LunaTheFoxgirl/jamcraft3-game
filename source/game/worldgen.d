module game.worldgen;
import dosimplex.generator;
import game.chunk;
import game.tiles;
import game.world;
import polyplex;
import config;

class WorldGenerator {
private:
    SNoiseGenerator ngen;
    World world;

public:
    this(World world) {
        ngen = SNoiseGenerator(SNoiseGenerator.DEFAULT_SEED);
        this.world = world;
    }

    double fractalBrownian(int octaves, double px, double py) {
        const double lacunarity = 1.9;
        const double gain = 0.65;

        double sum = 0.0;
        double amplitude = 1.0;

        foreach(i; 0..octaves) {
            sum += amplitude * ngen.noise2D(px, py);

            amplitude *= gain;

            px *= lacunarity;
            py  *= lacunarity;
        }

        return sum;
    }

    Chunk generateChunk(Vector2i position) {
        // if (position.Y == 1) {
        //     // TODO: Generate cave
        //     return GenerateFilled(position);
        // }


        Chunk chunk = new Chunk(world);
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
                    double px = (cast(double)(position.X*CHUNK_SIZE)/10)+(cast(double)i/10);
                    double py = (cast(double)(position.Y*CHUNK_SIZE)/10)+(cast(double)y/10);
                    double px2 = (cast(double)(position.X*CHUNK_SIZE)/10)+(cast(double)i/5);
                    double py2 = (cast(double)(position.Y*CHUNK_SIZE)/10)+(cast(double)y/5);

                    // Cacti placement
                    if ((position.Y*CHUNK_SIZE)+y >= height-1) {
                        double noise = ngen.noise2D(px2, py2);
                        if (noise >= 0.6 && noise <= 0.65) {
                                chunk.tiles[i][y] = new TallCactusTile()(Vector2i(i, y), false, chunk);
                        }
                        if (noise >= 0.2 && noise <= 0.25) {
                                chunk.tiles[i][y] = new TallCactusTile()(Vector2i(i, y), false, chunk);
                        }
                    }
                    if ((position.Y*CHUNK_SIZE)+y >= height) {


                        double noise = ngen.noise2D(px, py)*(fractalBrownian(2, px, py)/2);

                        if (noise > 0.5) {
                            if ((position.Y*CHUNK_SIZE)+y >= height+HARDSAND_START) {
                                chunk.walls[i][y] = new SandstoneTile()(Vector2i(i, y), true, chunk);
                            } else {
                                chunk.walls[i][y] = new SandTile()(Vector2i(i, y), true, chunk);
                            }
                        } else {
                            if ((position.Y*CHUNK_SIZE)+y >= height+HARDSAND_START) {
                                chunk.tiles[i][y] = new SandstoneTile()(Vector2i(i, y), false, chunk);
                                chunk.walls[i][y] = new SandstoneTile()(Vector2i(i, y), true, chunk);
                            } else {
                                chunk.tiles[i][y] = new SandTile()(Vector2i(i, y), false, chunk);
                                chunk.walls[i][y] = new SandTile()(Vector2i(i, y), true, chunk);
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

                    double pxCoal = (cast(double)(position.X*CHUNK_SIZE)/5)+(cast(double)x/5);
                    double pyCoal = (cast(double)(position.Y*CHUNK_SIZE)/5)+(cast(double)y/5);

                    if (fractalBrownian(4, px2, py2) < 0.1) {
                        if ((position.Y*CHUNK_SIZE)+y >= height+HARDSAND_START) {
                            Tile overlay = null;
                            if (ngen.noise2D(pxCoal, pyCoal)*ngen.noise2D(px, py) > 0.1) {
                                chunk.tiles[x][y] = new CoalTile()(Vector2i(x, y), false, chunk); //overlay = new CoalTile();
                            } else {
                                chunk.tiles[x][y] = new SandstoneTile()(Vector2i(x, y), false, chunk);
                            }
                        } else {
                            chunk.tiles[x][y] = new SandTile()(Vector2i(x, y), false, chunk);
                        }
                    }
                    if ((position.Y*CHUNK_SIZE)+y >= height+HARDSAND_START) {
                        chunk.walls[x][y] = new SandstoneTile()(Vector2i(x, y), true, chunk);
                    } else {
                        chunk.walls[x][y] = new SandTile()(Vector2i(x, y), true, chunk);
                    }
                }
            }
        }
        return chunk;
    }
}