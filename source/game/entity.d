module game.entity;
public import game.world;
public import game.tile;
public import game.chunk;
public import engine.cman;
import config;
import polyplex;

/++
    An entity

    Entities are dynamic things in the world which can change position.
+/
class Entity {
protected:
    World world;

public:
    /++
        Constructs a new entity.
    +/
    this(World world, Vector2 position) {
        this.world = world;
        this.position = position;
    }

    Vector2 position;

    Vector2i tilePosition() {
        return Vector2i(cast(int)position.X/TILE_SIZE, cast(int)position.Y/TILE_SIZE);
    }

    Vector2i chunkPosition() {
        return tilePosition/CHUNK_SIZE;
    }

    abstract Rectangle hitbox();
    abstract void update(GameTimes gameTime);
    abstract void draw(SpriteBatch spriteBatch);

    void drawAfter(SpriteBatch spriteBatch) {
        
    }
}