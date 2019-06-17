module game.tiles.cactus;
import game.tiles;
import polyplex;

class CactusTile : Tile {
public:
    this() {
        super("cactus");
        setTexture("cactus");
        setStrength(1);
        setHealth(5);
    }
}