module game.tiles.sandstonetile;
import game.tiles;

class SandstoneTile : Tile {
public:
    this() {
        super("sandstone");
        setTexture("sandstone");
        this.strength = 10;
        this.health = 20;
    }

    this(Vector2i position, Chunk chunk = null) {
        super("sandstone", position, chunk);
        setTexture("sandstone");
        this.strength = 10;
        this.health = 20;
    }
}
