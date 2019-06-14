module game.chunk;
import polyplex;
import std.format;
import msgpack;
import game.tiles;
import std.base64;
import std.file;
import std.path;

enum CHUNK_SIZE = 16;

enum CHUNK_SIZE_PIXELS = BLOCK_SIZE*CHUNK_SIZE;

class Chunk {
private:
    Rectangle hitbox;

public:
    void updateHitbox() {
        hitbox = new Rectangle(position.X*CHUNK_SIZE_PIXELS, position.Y*CHUNK_SIZE_PIXELS, BLOCK_SIZE*CHUNK_SIZE_PIXELS, BLOCK_SIZE*CHUNK_SIZE_PIXELS);
    }

    Rectangle getHitbox() {
        return hitbox;
    }

    // The list of tiles
    Tile[CHUNK_SIZE][CHUNK_SIZE] tiles;

    // The list of tiles
    Tile[CHUNK_SIZE][CHUNK_SIZE] walls;

    /// Position of the chunk
    Vector2i position;

    /// Has the chunk finished loading?
    @nonPacked
    bool loaded;

    /// Has the chunk been modified by a player?
    @nonPacked
    bool modified;

    /// Wether the chunk has been invalidated (marked for removal)
    @nonPacked
    bool invalidated;

    void draw(SpriteBatch spriteBatch, Rectangle viewport) {
        foreach(row; tiles) {
            foreach(block; row) {
                if (block is null) continue;
                if (block.hitbox.Intersects(viewport)) {
                    block.draw(spriteBatch);
                }
            }
        }
    }

    void drawWalls(SpriteBatch spriteBatch, Rectangle viewport) {
        foreach(row; walls) {
            foreach(block; row) {
                if (block is null) continue;
                if (block.hitbox.Intersects(viewport)) {
                    block.drawWall(spriteBatch);
                }
            }
        }
    }

    bool attackTile(Vector2i at, int digPower, bool wall) {
        if (!wall) {
            if (this.tiles[at.X][at.Y] !is null) {
                this.tiles[at.X][at.Y].attackTile(digPower, wall);
                return true;
            }
        } else {
            if (this.walls[at.X][at.Y] !is null) {
                this.walls[at.X][at.Y].attackTile(digPower, wall);
                return true;
            }
        }
        return false;
    }

    bool placeTile(T)(T tile, Vector2i at, int healAmount = 10) {
        if (this.tiles[at.X][at.Y] !is null) {
            this.tiles[at.X][at.Y].healDamage(healAmount);
            return false;
        }
        this.tiles[at.X][at.Y] = tile;
        this.tiles[at.X][at.Y].onInit(at, this);
        this.modified = true;
        return true;
    }

    bool placeWall(T)(T tile, Vector2i at, int healAmount = 10) {
        if (this.tiles[at.X][at.Y] !is null) {
            this.tiles[at.X][at.Y].healDamage(healAmount);
            return false;
        }
        this.walls[at.X][at.Y] = tile;
        this.walls[at.X][at.Y].onInit(at, this);
        this.modified = true;
        return true;
    }

    void update() {
        if (hitbox is null) {
            updateHitbox();
        }
    }

    void save() {
        import std.file;
        import std.path;

        if (!exists("world/")) mkdir("world/");
        write(buildPath("world", "%dx%d.chnk".format(position.X, position.Y)), pack!(true)(this));
    }
}

Chunk load(Vector2i position) {
    string path = buildPath("world", "%dx%d.chnk".format(position.X, position.Y));
    if (!exists("world/")) mkdir("world/");
    if (!exists(path)) return null;
    ubyte[] txt = cast(ubyte[])read(path);

    Chunk ch = unpack!(Chunk, true)(txt);
    foreach(x; 0..CHUNK_SIZE) {
        foreach(y; 0..CHUNK_SIZE) {
            if (ch.tiles[x][y] !is null) ch.tiles[x][y].onInit(Vector2i(x, y), ch);
            if (ch.walls[x][y] !is null) ch.walls[x][y].onInit(Vector2i(x, y), ch);
        }
    }
    return ch;
}

Chunk GenerateAir(Vector2i position) {
    Chunk output = new Chunk();
    output.position = position;
    output.loaded = true;
    output.modified = false;
    return output;
}

Chunk GenerateFilled(Vector2i position, string type = "sand") {
    Chunk output = new Chunk();
    output.position = position;
    output.loaded = true;
    output.modified = false;
    foreach(y; 0..CHUNK_SIZE) {
        foreach(x; 0..CHUNK_SIZE) {
            output.tiles[x][y] = new SandTile(Vector2i(x, y), output);
            output.walls[x][y] = new SandTile(Vector2i(x, y), output);
        }
    }
    return output;
}

void handlePackingChunk(ref Packer packer, ref Chunk chunk) {
    packer.beginMap(3).pack("tiles");
    packer.beginArray(CHUNK_SIZE);
    foreach(row; chunk.tiles) {
        packer.beginArray(CHUNK_SIZE);
        foreach(block; row) {
            packer.pack(block);
        }
    }

    packer.pack("walls");
    packer.beginArray(CHUNK_SIZE);
    foreach(row; chunk.walls) {
        packer.beginArray(CHUNK_SIZE);
        foreach(block; row) {
            packer.pack(block);
        }
    }

    packer.pack("position");
    packer.pack(chunk.position);
}

void handleUnpackingChunk(ref Unpacker unpacker, ref Chunk chunk) {
    unpacker.beginMap();
    string key;
    

    unpacker.unpack(key);
    unpacker.beginArray();
    foreach(x; 0..CHUNK_SIZE) {
        unpacker.beginArray();
        foreach(y; 0..CHUNK_SIZE) {
            unpacker.unpack(chunk.tiles[x][y]);
        }
    }
    
    unpacker.unpack(key);
    unpacker.beginArray();
    foreach(x; 0..CHUNK_SIZE) {
        unpacker.beginArray();
        foreach(y; 0..CHUNK_SIZE) {
            unpacker.unpack(chunk.walls[x][y]);
        }
    }

    unpacker.unpack(key);
    unpacker.unpack!Vector2i(chunk.position);
}

void registerChunkIO() {
    registerPackHandler!(Chunk, handlePackingChunk);
    registerUnpackHandler!(Chunk, handleUnpackingChunk);
}