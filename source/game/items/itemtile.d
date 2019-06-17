module game.items.itemtile;
import game.item;
import game.tile;
import game.tiles;
import game.utils;
import polyplex;

/++
    Item matching a tile.
+/
class ItemTile : Item  {
private:
    Texture2D getTexture() {
        return TEXTURES["tiles/tile_"~texture];
    }

    bool placeTile(T)(T tile, Vector2i at, bool isWall) {
        // Get the chunk where the tile should be placed
        chunkAtScreen = at.tilePosToChunkPos;
        Chunk chunk = world[chunkAtScreen.X, chunkAtScreen.Y];

        // Calculate the tilepos within
        Vector2i tilePos = at.wrapTilePos;

        // Handle wall case
        if (isWall)  return chunk.placeWall(tile, tilePos, stats.pickPower*2);
        
        // Get tile position in pixels as a rectangle via default collission
        Vector2i px = at.toPixels;
        Rectangle tileBounds = getDefaultHB(px);

        // If the tile would be in the way cancel.
        if (tileBounds.Intersects(this.hitbox)) return false;

        // Try to place tile
        return chunk.placeTile(tile, tilePos, stats.pickPower*2);
    }

public:
    this() {
        super("tile");
    }

    override void onInit(string tileId) {
        Tile t = TileRegistry.createNew(subId);
        setTexture(t.getTextureName());
    }

    override bool onUse(Vector2i at, bool alt) {
        return placeTile(TileRegistry.createNew(subId), at, alt);
    }

    override void onRender(Rectangle area, SpriteBatch spriteBatch) {
         spriteBatch.Draw(getTexture(), area, getTexture().Size, Color.White);       
    }
}