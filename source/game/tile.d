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

class Reservation {
    Vector2i origin;
    Vector2i size;
}

class Tile {
private:
    @nonPacked
    World world;
    
    @nonPacked
    bool collidable = true;

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

    @nonPacked
    string name;

    @nonPacked
    string description;

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
    string texture;

    @nonPacked
    string wallTexture;

    /// The id of a tile
    @nonPacked
    string tileId;
    

    /++
        Set name shown as Item
    +/
    final void setName(string name) {
        this.name = name;
    }

    /++
        Set description shown as Item
    +/
    final void setDescription(string description) {
        this.description = description;
    }

    /++
        Set how much light this emits.
    +/
    final void setLightEmission(float amount) {
        this.lightEmission = amount;
    }

    /++
        Set how much light this absorbs
    +/
    final void setAbsorbtion(float amount) {
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
        this.texture = name;
    }

    final void setWallTexture(string name) {
        this.wallTexture = name;
    }

    final Texture2D getTexture() {
        return TEXTURES["tiles/tile_%s".format(this.texture)];
    }

    final Texture2D getWallTexture() {
        if (wallTexture is null) return getTexture();
        return TEXTURES["tiles/tile_%s".format(this.texture)];
    }

    final void setCollidable(bool isCollidable) {
        this.collidable = isCollidable;
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

    Reservation getReservation() {
        return null;
    }

    void onSaving(ref Packer packer) { }
    void onLoading(ref Unpacker unpacker) { }

public:

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

    final bool isCollidable() {
        return collidable;
    }

    final string getId() {
        return tileId;
    }
    
    final string getName() {
        return name;
    }

    final string getDescription() {
        return description;
    }

    final float getLightBlock() {
        return lightBlocking;
    }

    final float getEmission() {
        return lightEmission;
    }

    final string getTextureName() {
        return this.texture;
    }

    final string getWallTextureName() {
        return this.wallTexture;
    }

    final void draw(SpriteBatch spriteBatch) {
        if (breakAnim is null) {
            breakAnim = TEXTURES["fx/fx_break"];
        }

        // Handle the cute animation
        if (hitScaleEff > 0) {
            hitScaleEff -= HIT_SCALE_FALLOFF;
        }
        if (hitScaleEff < 0) {
            hitScaleEff += HIT_SCALE_FALLOFF;
        }

        // Draw
        spriteBatch.Draw(getTexture(), getRenderBox, getTexture().Size, FGColor);
        drawBreakAnim(spriteBatch);
    }

    final void drawWall(SpriteBatch spriteBatch) {

        // Handle the cute animation
        if (hitScaleEff > 0) {
            hitScaleEff--;
        }
        if (hitScaleEff < 0) {
            hitScaleEff++;
        }

        spriteBatch.Draw(getWallTexture(), getRenderBox, getWallTexture().Size, BGColor);
        drawBreakAnim(spriteBatch);
    }

    final void playInitAnimation() {
        // Apply the lil' cute effect.
        hitScaleEff = -(HIT_SCALE_EFF_MAX*2);
    }

    /++
        Heals any damage done to the block.
    +/
    final void healDamage(int amount) {
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
    final void attackTile(int digPower, bool wall = false) {
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
    final void breakTile(bool wall = false) {
        this.onDestroy();
        chunk.modified = true;
        // TODO: update shadow mapping.
        chunk.updateLighting(1);
        if (!wall) {
            chunk.tiles[position.X][position.Y] = null;
            return;
        } 
        chunk.walls[position.X][position.Y] = null;

        if (this.getReservation() !is null) {
            WORLD.getProvider().removeReservation(this);
        }
    }

    final bool use() {
        return onUse();
    }

    @nonPacked
    Vector2i getWorldPosition() {
        return Vector2i(
            (position.X*TILE_SIZE)+(chunk.position.X*CHUNK_SIZE*TILE_SIZE),
            (position.Y*TILE_SIZE)+(chunk.position.Y*CHUNK_SIZE*TILE_SIZE));
    }

    bool canPlace(Vector2i position, bool wall) {
        return true;
    }

    final Tile opCall(Vector2i position, Chunk chunk = null) {
        onInit(position, chunk);
        return this;
    }

    void onInit(Vector2i position, Chunk chunk = null) {
        this.chunk = chunk;
        this.position = position;
        Vector2i wPosition = getWorldPosition();
        this.hitbox = getDefaultHB(wPosition);
        this.renderbox = new Rectangle(wPosition.X, wPosition.Y, TILE_SIZE, TILE_SIZE);
        if (this.getReservation() !is null) {
            WORLD.getProvider().setReservation(this, this.getReservation());
        }
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