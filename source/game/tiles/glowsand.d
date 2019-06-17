module game.tiles.glowsand;
import game.tiles;

class GlowsandTile : Tile {
public:
    this() {
        super("glowsand");
        setTexture("sand");
        setName("Sand?");
        setDescription("It glows mysteriously...");
        setStrength(1);
        setHealth(10);
        setLightEmission(2f);
    }
}
