module game.tile;
import polyplex;
import engine.cman;
import game.chunk;
import game.tiles;
import std.format;
import engine.registry;
import msgpack;

enum BLOCK_SIZE = 16;

enum BLOCK_HB_SHRINK = 4;

private static Color FGColor;
private static Color BGColor;

static this() {
    FGColor = Color.White;
    BGColor = new Color(169, 169, 169);
}

class Tile {
private:
    @nonPacked
    int maxHealth;

    @nonPacked
    int strength;

    @nonPacked
    static Texture2D breakAnim;

    Rectangle getBreakAnimStep() {
        float percentage = 0f;
        if (maxHealth > 0) {
            percentage = cast(float)health/cast(float)maxHealth;
        }
        int index = 3-cast(int)(percentage*4);
        int fWidth = breakAnim.Width()/4;

        return new Rectangle(index*fWidth, 0, fWidth, breakAnim.Height);
    }

    final void drawBreakAnim(SpriteBatch spriteBatch) {
        if (health != maxHealth) {
            spriteBatch.Draw(breakAnim, renderbox, getBreakAnimStep(), Color.White);
        }
    }

protected:
    @nonPacked
    int health;

    @nonPacked
    Chunk chunk;

    @nonPacked
    Texture2D texture;

    /// The id of a tile
    @nonPacked
    string tileId;
    
    /++
        Sets the strength of the tile, set to -1 for indestructible.
    +/
    final void setStrength(int strength) {
        this.strength = strength;
    }

    /++
        Set the max and current health of the tile
    +/
    final void setHealth(int health) {
        this.maxHealth = health;
        this.health = maxHealth;
    }

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

    /++
        Heals any damage done to the block.
    +/
    void healDamage(int amount) {
        // If health is already full, escape early.
        if (this.health == maxHealth) return;

        // If healing amount is less than 0, instant heal.
        if (amount < 0) {
            this.health = maxHealth;
            return;
        }

        // Heal the tile
        this.health += amount;
        if (this.health > maxHealth) this.health = maxHealth;
    }

    /++
        Attacks the tile, dealing damage to it if you have enough dig power.
    +/
    void attackTile(int digPower, bool wall = false) {
        // If the strength is less than 0, it's indestructible.
        if (strength < 0) return;

        // If you don't have enough dig power, it's indestructible.
        if (digPower < strength) return;

        // Decrease health.
        health -= digPower;
        if (health <= 0) breakTile(wall);
    }

    /++
        Instantly breaks the tile
    +/
    void breakTile(bool wall = false) {
        this.onDestroy();
        chunk.modified = true;
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
        drawBreakAnim(spriteBatch);
    }

    void drawWall(SpriteBatch spriteBatch) {
        spriteBatch.Draw(texture, renderbox, texture.Size, BGColor);
        drawBreakAnim(spriteBatch);
    }

    void onInit(Vector2i position, Chunk chunk = null) {
        if (breakAnim is null) {
            breakAnim = TEXTURES["fx/fx_break"];
        }
        this.chunk = chunk;

        this.position = position;
        Vector2i wPosition = getWorldPosition();
        this.hitbox = getDefaultHB(wPosition);
        this.renderbox = new Rectangle(wPosition.X, wPosition.Y, BLOCK_SIZE, BLOCK_SIZE);
    }
}

Rectangle getDefaultHB(Vector2i worldPosition) {
    return new Rectangle(
        worldPosition.X+BLOCK_HB_SHRINK, 
        worldPosition.Y+BLOCK_HB_SHRINK, 
        BLOCK_SIZE-(BLOCK_HB_SHRINK*2), 
        BLOCK_SIZE-(BLOCK_HB_SHRINK*2));
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