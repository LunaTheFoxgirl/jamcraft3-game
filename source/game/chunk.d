module game.chunk;
import polyplex;
import std.format;
import msgpack;
import game.tiles;
import game.utils;
import game.world;
import std.base64;
import std.file;
import std.path;
import std.parallelism;
import game.lighting.lman;
import game.lighting.smap;
import config;

class Chunk {
private:
    @nonPacked
    Rectangle hitbox;

    @nonPacked
    World world;

public:
    ~this() {
    }

    this(World world) {
        this.world = world;
    }

    void updateHitbox() {
        hitbox = new Rectangle(position.X*CHUNK_SIZE_PIXELS, position.Y*CHUNK_SIZE_PIXELS, CHUNK_SIZE_PIXELS, CHUNK_SIZE_PIXELS);
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

    bool useTile(Vector2i at) {
        if (this.tiles[at.X][at.Y] !is null) {
            return this.tiles[at.X][at.Y].use();
        }
        return false;
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

    void updateLighting(int adj = 0) {
        // if (adj > 0) {
            // world.invalidateLightArea(position, adj, adj);
        // } else {
            // world.getLighting.notifyUpdate(position);
        // }
    }

    bool placeTile(T)(T tile, Vector2i at, int healAmount = 10) {
        return place(tile, at, false, healAmount);
    }

    bool placeWall(T)(T tile, Vector2i at, int healAmount = 10) {
        return place(tile, at, true, healAmount);
    }

    bool place(T)(T tile, Vector2i at, bool wall, int healAmount = 10) {

        // Make sure we don't try to access a tile outside the chunk.
        if (!at.withinChunkBounds) return false;
        
        // Make sure this chunk isn't null, can happen in rare cases.
        if (this is null) return false;
        

        // Check if the tile is allowed to be placed there.
        Vector2i worldPosition = position.chunkPosToTilePos+at;
        if (!tile.canPlace(worldPosition, wall)) return false;

        if (!wall) {
            
            // Check is the slot is reserved, if so heal it.
            Tile reservedOwner = WORLD.getProvider().inReservedArea(worldPosition);
            if (reservedOwner !is null) {
                reservedOwner.healDamage(healAmount);
                return false;
            }

            // Check if there's a tile on that spot, if so heal it.
            if (this.tiles[at.X][at.Y] !is null) {
                this.tiles[at.X][at.Y].healDamage(healAmount);
                return false;
            }
        } else {

            // Walls don't have reservations (at the moment)
            if (this.walls[at.X][at.Y] !is null) {
                this.walls[at.X][at.Y].healDamage(healAmount);
                return false;
            }
        }

        setTile(tile, at, wall);
        return true;
    }

    void setTile(T)(T tile, Vector2i at, bool wall) {
        if (wall) {
            this.walls[at.X][at.Y] = tile;
            this.walls[at.X][at.Y](at, true, this);
            this.walls[at.X][at.Y].playInitAnimation();
            this.walls[at.X][at.Y].updateSurrounding(at);
        } else {
            this.tiles[at.X][at.Y] = tile;
            this.tiles[at.X][at.Y](at, false, this);
            this.tiles[at.X][at.Y].playInitAnimation();
            this.tiles[at.X][at.Y].updateSurrounding(at);
        }
        this.modified = true;
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


Chunk load(Vector2i position, World world) {
    string path = buildPath("world", "%dx%d.chnk".format(position.X, position.Y));
    if (!exists("world/")) mkdir("world/");
    if (!exists(path)) return null;
    ubyte[] txt = cast(ubyte[])read(path);

    Chunk ch = unpack!(Chunk, true)(txt);
    ch.world = world;
    foreach(x; 0..CHUNK_SIZE) {
        foreach(y; 0..CHUNK_SIZE) {
            if (ch.tiles[x][y] !is null) ch.tiles[x][y](Vector2i(x, y), false, ch);
            if (ch.walls[x][y] !is null) ch.walls[x][y](Vector2i(x, y), true, ch);
        }
    }
    return ch;
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