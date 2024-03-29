module game.tiles.cactusplatform;
import game.tiles;
import polyplex;

class CactusPlatformTile : Tile {
public:
    this() {
        super("cactusplatform");
        setTexture("cactusplatform");
        setName("Cactus Platform");
        setDescription("Going up a level!");
        setStrength(1);
        setHealth(10);
        setLightEmission(2f);
    }

    override bool canPlace(Vector2i position, bool wall) {
        return !wall;
    }

    override bool isCollidableWith(Entity e, Vector2 targetVelocity) {
        return (targetVelocity.X == 0 && targetVelocity.Y > 0) && (e.feet.Y < hitbox.Y+3) && Keyboard.GetState().IsKeyUp(Keys.S);
    }
}
