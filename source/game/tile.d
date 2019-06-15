module game.tile;
import polyplex;
import engine.cman;
import game.chunk;
import game.tiles;
import std.format;
import engine.registry;
import msgpack;
import config;


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
    float hitScaleEff = 0f;

    @nonPacked
    float lightBlocking = 0.2f;

    @nonPacked
    float lightEmission = 0.0f;

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
            spriteBatch.Draw(breakAnim, getRenderBox, getBreakAnimStep(), Color.White);
        }
    }

    final Rectangle getRenderBox() {
        float efDouble = hitScaleEff*2;
        int px = cast(int)(cast(float)renderbox.X-hitScaleEff);
        int py = cast(int)(cast(float)renderbox.Y-hitScaleEff);
        int pw = cast(int)(cast(float)renderbox.Width+efDouble);
        int ph = cast(int)(cast(float)renderbox.Height+efDouble);
        return new Rectangle(px, py, pw, ph);
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
        Set how much light this emits.
    +/
    final void setLightEmission(float amount) {
        this.lightEmission = amount;
    }

    /++
        Set how much light this blocks
    +/
    final void setLightBlock(float amount) {
        this.lightBlocking = amount;
    }

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

        // Apply the lil' cute effect.
        hitScaleEff = -HIT_SCALE_EFF_MAX;

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

        // Apply the lil' cute effect.
        hitScaleEff = HIT_SCALE_EFF_MAX;

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
        // TODO: update shadow mapping.
        if (!wall) {
            chunk.tiles[position.X][position.Y] = null;
            return;
        } 
        chunk.walls[position.X][position.Y] = null;
    }

    bool use() {
        return onUse();
    }

    @nonPacked
    Vector2i getWorldPosition() {
        return Vector2i(
            (position.X*TILE_SIZE)+(chunk.position.X*CHUNK_SIZE*TILE_SIZE),
            (position.Y*TILE_SIZE)+(chunk.position.Y*CHUNK_SIZE*TILE_SIZE));
    }

    void draw(SpriteBatch spriteBatch) {

        // Handle the cute animation
        if (hitScaleEff > 0) {
            hitScaleEff -= HIT_SCALE_FALLOFF;
        }
        if (hitScaleEff < 0) {
            hitScaleEff += HIT_SCALE_FALLOFF;
        }

        // Draw
        spriteBatch.Draw(texture, getRenderBox, texture.Size, FGColor);
        drawBreakAnim(spriteBatch);
    }

    void drawWall(SpriteBatch spriteBatch) {

        // Handle the cute animation
        if (hitScaleEff > 0) {
            hitScaleEff--;
        }
        if (hitScaleEff < 0) {
            hitScaleEff++;
        }

        spriteBatch.Draw(texture, getRenderBox, texture.Size, BGColor);
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
        this.renderbox = new Rectangle(wPosition.X, wPosition.Y, TILE_SIZE, TILE_SIZE);
    }

    final void playInitAnimation() {
        // Apply the lil' cute effect.
        hitScaleEff = -HIT_SCALE_EFF_MAX;
    }

    final float getLightBlock() {
        return lightBlocking;
    }

    final float getEmission() {
        return lightEmission;
    }
}

Rectangle getDefaultHB(Vector2i worldPosition) {
    return new Rectangle(
        worldPosition.X+TILE_HB_SHRINK, 
        worldPosition.Y+TILE_HB_SHRINK, 
        TILE_SIZE-(TILE_HB_SHRINK*2), 
        TILE_SIZE-(TILE_HB_SHRINK*2));
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