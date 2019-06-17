module game.tiles.sandstonetile;
import game.tiles;

class SandstoneTile : Tile {
public:
    this() {
        super("sandstone");
        setTexture("sandstone");
        setStrength(1);
        setHealth(20);
    }
}
