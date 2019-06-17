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

    override bool isCollidableWith(Entity e) {
        return (e.motion.Y > 0 && Keyboard.GetState().IsKeyUp(Keys.S));
    }
}
