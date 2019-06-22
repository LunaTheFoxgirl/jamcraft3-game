module game.entity;
public import game.world;
public import game.tile;
public import game.chunk;
public import engine.cman;
public import game.physics.coll;
import game.physics.phys;
import game.utils;
import config;
import polyplex;

/++
    An entity

    Entities are dynamic things in the world which can change position.
+/
class Entity : PhysicsObject {
protected:
    World world;
    void onUpdate(GameTimes gameTime) {}
    void onDraw(SpriteBatch spriteBatch) {}

public:
    /++
        Constructs a new entity.
    +/
    this(World world, Vector2 position, Rectangle hitbox) {
        this.world = world;
        this.position = position;
        super(Vector2(hitbox.X, hitbox.Y), Vector2(hitbox.Width, hitbox.Height));
    }

    Vector2i tilePosition() {
        return Vector2i(cast(int)position.X/TILE_SIZE, cast(int)position.Y/TILE_SIZE);
    }

    Vector2i chunkPosition() {
        return tilePosition/CHUNK_SIZE;
    }

    final void update(GameTimes gameTime) {
        updateHitbox();
        onUpdate(gameTime);
    }

    final void draw(SpriteBatch spriteBatch) {
        onDraw(spriteBatch);
    }

    void drawAfter(SpriteBatch spriteBatch) {
        
    }
}