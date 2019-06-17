module game.tiles.sandtile;
import game.tiles;

class SandTile : Tile {
public:
    this() {
        super("sand");
        setTexture("sand");
        setName("Sand");
        setDescription("As a wise young man once said; I don't like sand.");
        setStrength(1);
        setHealth(10);
    }
}
