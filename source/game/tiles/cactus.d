module game.tiles.cactus;
import game.tiles;
import polyplex;

class CactusTile : Tile {
public:
    this() {
        super("cactus");
        setName("Cactus");
        setDescription("It stings!");
        setTexture("cactus");
        setStrength(1);
        setHealth(5);
    }
}