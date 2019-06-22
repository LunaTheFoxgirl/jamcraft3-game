module game.tiles.sandtile;
import game.tiles;

class SandTile : Tile {
public:
    this() {
        super("sand");
        setTexture("sand");
        setName("Sand");
        setDescription("As a young man once said:\n\"I don't like sand.\"");
        setStat("Courseness", "Very");
        setStat("Roughness", "Maximum");
        setStat("Gets Everywhere", "Definately");
        setStrength(1);
        setHealth(10);
    }
}
