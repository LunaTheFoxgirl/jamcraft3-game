module game.tiles.sandtile;
import game.tiles;

class SandTile : Tile {
public:
    this() {
        super("sand");
        setTexture("sand");
        setStrength(1);
        setHealth(10);
    }
}
