module game.tile;
import polyplex;
import engine.cman;
import game.chunk;
import game.tiles;
import std.format;
import engine.registry;
import msgpack;

enum BLOCK_SIZE = 16;

private static Color FGColor;
private static Color BGColor;

static this() {
    FGColor = Color.White;
    BGColor = new Color(169, 169, 169);
}

class Tile {
protected:
    @nonPacked
    Chunk chunk;

    @nonPacked
    Texture2D texture;

    /// The id of a tile
    @nonPacked
    string tileId;

    final void setTexture(string name) {
        this.texture = TEXTURES["tiles/tile_%s".format(name)];
    }

    /++
        onUse is called when the tile is used (clicked on)

        Returns:
            true if an action has been done.
            false if no action has been done.
    +/
    bool onUse() {
        return false;
    }

    /++
        onDestroy is called when the tile is destroyed

        Returns:
            true if an action has been done.
            false if no action has been done.
    +/
    bool onDestroy() {
        return false;
    }

    void onSaving(ref Packer packer) { }
    void onLoading(ref Unpacker unpacker) { }

public:
    string getId() {
        return tileId;
    }

    @nonPacked
    int health;

    @nonPacked
    int strength;

    /// Position of tile in chunk
    @nonPacked
    Vector2i position;

    /// Position of hitbox
    @nonPacked
    Rectangle hitbox;

    /// Position of hitbox
    @nonPacked
    Rectangle renderbox;

    this() {
        this("INVALID_TILE");
    }

    this(string tileId) {
        this.tileId = tileId;
    }

    this(string tileId, Vector2i position, Chunk chunk = null) {
        this(tileId);
        onInit(position, chunk);
    }

    void attackTile(int digPower, bool wall = false) {
        if (digPower < strength) return;
        health -= digPower;
        if (health <= 0) breakTile(wall);
    }

    void breakTile(bool wall = false) {
        this.onDestroy();
        if (!wall) {
            chunk.tiles[position.X][position.Y] = null;
            return;
        } 
        chunk.walls[position.X][position.Y] = null;
    }

    @nonPacked
    Vector2i getWorldPosition() {
        return Vector2i(
            (position.X*BLOCK_SIZE)+(chunk.position.X*CHUNK_SIZE*BLOCK_SIZE),
            (position.Y*BLOCK_SIZE)+(chunk.position.Y*CHUNK_SIZE*BLOCK_SIZE));
    }

    void draw(SpriteBatch spriteBatch) {
        spriteBatch.Draw(texture, renderbox, texture.Size, FGColor);
    }

    void drawWall(SpriteBatch spriteBatch) {
        spriteBatch.Draw(texture, renderbox, texture.Size, BGColor);
    }

    void onInit(Vector2i position, Chunk chunk = null) {
        this.chunk = chunk;

        this.position = position;
        Vector2i wPosition = getWorldPosition();
        this.hitbox = new Rectangle(wPosition.X+4, wPosition.Y+4, BLOCK_SIZE-4, BLOCK_SIZE-4);
        this.renderbox = new Rectangle(wPosition.X, wPosition.Y, BLOCK_SIZE, BLOCK_SIZE);
    }
}

void handlePackingTile(T)(ref Packer packer, ref T tile) {
    string tid = tile.tileId;
    packer.packMap("blockId", tid);
    tile.onSaving(packer);
}

void handleUnpackingTile(T)(ref Unpacker unpacker, ref T tile) {
    string key;
    string tid;
    
    /// Main
    unpacker.unpackMap(key, tid);
    tile = cast(T)TileRegistry.createNew(tid);

    tile.onLoading(unpacker);
}

void registerTileIOFor(T)() {
    registerPackHandler!(T, handlePackingTile!T);
    registerUnpackHandler!(T, handleUnpackingTile!T);
}