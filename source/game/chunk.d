module game.chunk;
import game.block;
import polyplex;
import std.format;
import msgpack;

enum CHUNK_SIZE = 16;

class Chunk {
public:
    // The list of blocks
    Block[CHUNK_SIZE][CHUNK_SIZE] blocks;

    // The list of blocks
    Block[CHUNK_SIZE][CHUNK_SIZE] walls;

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
        foreach(row; blocks) {
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

    void update() {

    }

    void save() {
        import std.file;
        import std.path;

        if (!exists("world/")) mkdir("world/");
        write(buildPath("world", "%dx%d.chnk".format(position.X, position.Y)), pack(this));
    }
}

Chunk load(Vector2i position) {
    import std.file;
    import std.path;
    import std.format;
    string path = buildPath("world", "%dx%d.chnk".format(position.X, position.Y));
    if (!exists("world/")) mkdir("world/");
    if (!exists(path)) return null;
    Chunk ch = unpack!Chunk(cast(ubyte[])read(path));
    foreach(x; 0..CHUNK_SIZE) {
        foreach(y; 0..CHUNK_SIZE) {
            if (ch.blocks[x][y] !is null) ch.blocks[x][y].initBlock(Vector2i(x, y), ch);
            if (ch.walls[x][y] !is null) ch.walls[x][y].initBlock(Vector2i(x, y), ch);
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
            output.blocks[x][y] = new Block(Vector2i(x, y), "sand", output);
            output.walls[x][y] = new Block(Vector2i(x, y), "sand", output);
        }
    }
    return output;
}