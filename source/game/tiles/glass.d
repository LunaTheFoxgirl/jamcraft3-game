module game.tiles.glass;
import game.tiles;
import polyplex;

class GlassTile : Tile {
public:
    this() {
        super("glass");
        setName("Glass");
        setDescription("I can see through this");
        setTexture("glass");
        setStrength(1);
        setHealth(2);
    }
}