module game.tiles.cactusbase;
import game.tiles;
import polyplex;

class CactusBaseTile : Tile {
public:
    this() {
        super("cactusbase");
        setTexture("cactusbase");
        setName("Cactus Base");
        setDescription("Used to make a crafting table");
        setStrength(1);
        setHealth(20);
        setCollidable(false);
    }

    override bool canPlace(Vector2i position, bool wall) {
        if (wall) return false;
        return WORLD.tileAt(Vector2i(position.X, position.Y+1)) !is null;
    }

    override void onUpdate() {
        Vector2i inWorld = getWorldPosition();

        if (WORLD.tileAt(Vector2i(inWorld.X, inWorld.Y+1)) is null) {
            this.breakTile(WORLD.getPlayer());
        }
    }
}