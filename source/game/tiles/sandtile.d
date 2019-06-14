module game.tiles.sandtile;
import game.tiles;

class SandTile : Tile {
public:
    this() {
        super("sand");
        setTexture("sand");
        this.strength = 1;
        this.health = 10;
    }
    
    this(Vector2i position, Chunk chunk = null) {
        super("sand", position, chunk);
        setTexture("sand");
        this.strength = 1;
        this.health = 10;
    }
}
