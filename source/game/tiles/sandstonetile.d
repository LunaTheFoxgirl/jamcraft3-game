module game.tiles.sandstonetile;
import game.tiles;

class SandstoneTile : Tile {
public:
    this() {
        super("sandstone");
        setTexture("sandstone");
    }

    this(Vector2i position, Chunk chunk = null) {
        super("sandstone", position, chunk);
        setTexture("sandstone");
    }
}
