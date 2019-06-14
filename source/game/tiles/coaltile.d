module game.tiles.coaltile;
import game.tiles;

class CoalTile : Tile {
public:
    this() {
        super("coal");
        setTexture("coal");
        setStrength(10);
        setHealth(20);
    }

    this(Vector2i position, Chunk chunk = null) {
        super("coal", position, chunk);
        setTexture("coal");
        setStrength(10);
        setHealth(20);
    }
}