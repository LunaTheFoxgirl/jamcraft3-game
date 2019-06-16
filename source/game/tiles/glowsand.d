module game.tiles.glowsand;
import game.tiles;

class GlowsandTile : Tile {
public:
    this() {
        super("glowsand");
        setTexture("sand");
    }
    
    this(Vector2i position, Chunk chunk = null) {
        super("glowsand", position, chunk);
        setTexture("sand");
    }

    override void onInit(Vector2i position, Chunk chunk) {
        super.onInit(position, chunk);
        setStrength(1);
        setHealth(10);
        setLightEmission(2f);
    }
}
