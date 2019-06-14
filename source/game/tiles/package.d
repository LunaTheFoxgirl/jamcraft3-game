module game.tiles;
import engine.registry;
public import polyplex.math;
public import game.chunk;
public import game.tile;
public import game.tiles.sandtile;
public import game.tiles.sandstonetile;

__gshared static Registry!Tile TileRegistry;

Tile createTile(string id, Vector2i position, Chunk chunk = null) {
    Tile t = TileRegistry.createNew(id);
    t.onInit(position, chunk);
    return t;
}

private void registerTile(T)(string name) if (is(T : Tile)) {
    TileRegistry.register!T(name);
    registerTileIOFor!T();
}

void initRegistry() {
    TileRegistry = new Registry!Tile();
    registerTile!SandTile("sand");
    registerTile!SandstoneTile("sandstone");
}