module game.tiles.cactus;
import game.tiles;
import polyplex;
import game.itemstack;
import game.items;

class CactusTile : Tile {
public:
    this() {
        super("cactus");
        setName("Cactus");
        setDescription("It stings!");
        setTexture("cactus");
        setStrength(1);
        setHealth(5);
    }

    override ItemStack getDrops() {
        return new ItemStack(new ItemCactus(), 1);
    }
}