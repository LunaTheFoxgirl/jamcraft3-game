module game.items.itemcactus;
import engine.cman;
import game.item;
import game.tiles;
import game.entity;
import polyplex;

class ItemCactus : Item {
public:
    this() {
        super("cactus");

        setConsumable(true);
        setTexture("cactus");
        setUseTime(10);
        setName("Cactus");
        setDescription("It stings!");
    }

    override bool onUse(Entity user, Vector2i at, bool alt) {
        return placeTile(user, TileRegistry.createNew("cactus"), at, alt);
    }
}