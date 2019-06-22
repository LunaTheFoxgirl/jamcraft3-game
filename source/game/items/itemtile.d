module game.items.itemtile;
import engine.cman;
import game.item;
import game.tiles;
import game.entity;
import polyplex;

/++
    Item matching a tile.
+/
class ItemTile : Item  {
private:
    Texture2D getTexture() {
        return TEXTURES["tiles/tile_"~getTextureName()];
    }

public:
    this() {
        super("tile");
    }

    override void onInit(string tileId) {
        Tile t = TileRegistry.createNew(tileId);

        setConsumable(true);
        setHasSubTypes(true);
        setSubId(tileId);
        setTexture(t.getTextureName());
        setUseTime(10);
        setName(t.getName());
        setDescription(t.getDescription());
    }

    override bool onUse(Entity user, Vector2i at, bool alt) {
        return placeTile(user, TileRegistry.createNew(getSubId()), at, alt);
    }

    override void onRender(Rectangle area, SpriteBatch spriteBatch) {
         spriteBatch.Draw(getTexture(), area, getTexture().Size, Color.White);       
    }
}