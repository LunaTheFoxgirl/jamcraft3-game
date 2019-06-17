module game.items.itemtile;
import engine.cman;
import game.item;
import game.tile;
import game.tiles;
import game.utils;
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

    bool placeTile(T)(Entity user, T tile, Vector2i at, bool isWall) {
        // Get the chunk where the tile should be placed
        Vector2i chunkAtScreen = at.tilePosToChunkPos;
        Chunk chunk = WORLD[chunkAtScreen.X, chunkAtScreen.Y];

        // Calculate the tilepos within
        Vector2i tilePos = at.wrapTilePos;

        // Handle wall case
        if (isWall)  return chunk.placeWall(tile, tilePos, 2);
        
        // Get tile position in pixels as a rectangle via default collission
        Vector2i px = at.toPixels;
        Rectangle tileBounds = getDefaultHB(px);

        // If the tile would be in the way cancel.
        if (tileBounds.Intersects(user.hitbox)) return false;

        // Try to place tile
        return chunk.placeTile(tile, tilePos, 2);
    }

public:
    this() {
        super("tile");
    }

    override void onInit(string tileId) {
        Tile t = TileRegistry.createNew(tileId);

        setHasSubTypes(true);
        setSubId(tileId);
        setTexture(t.getTextureName());
        setUseTime(10);
        setName(t.getName());
        setDescription(t.getDescription());
    }

    override bool onUse(Entity user, Vector2i at, bool alt) {
        Logger.Info("Trying to place {1} at {0}", at, getSubId());
        return placeTile(user, TileRegistry.createNew(getSubId()), at, alt);
    }

    override void onRender(Rectangle area, SpriteBatch spriteBatch) {
         spriteBatch.Draw(getTexture(), area, getTexture().Size, Color.White);       
    }
}