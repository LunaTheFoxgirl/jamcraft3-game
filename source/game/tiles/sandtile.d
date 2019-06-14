module game.tiles.sandtile;
import game.tiles;

class SandTile : Tile {
public:
    this() {
        super("sand");
        setTexture("sand");
    }
    
    this(Vector2i position, Chunk chunk = null) {
        super("sand", position, chunk);
        setTexture("sand");
    }

    override void onInit(Vector2i position, Chunk chunk) {
        super.onInit(position, chunk);
        setStrength(1);
        setHealth(10);
    }
}
