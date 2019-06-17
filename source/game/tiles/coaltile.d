module game.tiles.coaltile;
import game.tiles;

class CoalTile : Tile {
public:
    this() {
        super("coal");
        setTexture("coal");
        setName("Coal Ore");
        setDescription("It's p chunky");
        setStrength(10);
        setHealth(20);
    }
}