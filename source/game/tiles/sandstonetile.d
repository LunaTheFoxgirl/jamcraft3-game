module game.tiles.sandstonetile;
import game.tiles;

class SandstoneTile : Tile {
public:
    this() {
        super("sandstone");
        setTexture("sandstone");
        setName("Sandstone");
        setDescription("Sand, but hard!");
        setStrength(1);
        setHealth(20);
    }
}
