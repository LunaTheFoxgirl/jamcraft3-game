module game.tiles.coaltile;
import game.tiles;

class CoalTile : Tile {
public:
    this() {
        super("coal");
        setTexture("coal");
        this.strength = 10;
        this.health = 20;
    }

    this(Vector2i position, Chunk chunk = null) {
        super("coal", position, chunk);
        setTexture("coal");
        this.strength = 10;
        this.health = 20;
    }
}