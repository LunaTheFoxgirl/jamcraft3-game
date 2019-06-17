module game.tiles;
import polyplex;
import engine.registry;
public import polyplex.math;
public import game.world;
public import game.chunk;
public import game.entity;
public import game.tile;
public import game.tiles.sandtile;
public import game.tiles.sandstonetile;
public import game.tiles.coaltile;
public import game.tiles.cactusplatform;
public import game.tiles.cactusbase;
public import game.tiles.cactus;

__gshared static Registry!Tile TileRegistry;

Tile createTile(string id, Vector2i position, bool wall, Chunk chunk = null) {
    Tile t = TileRegistry.createNew(id);
    t(position, wall, chunk);
    return t;
}

private void registerTile(T)() if (is(T : Tile)) {
    T tx = new T;
    string name = tx.getId;
    Logger.Info("[TileRegistry] Registering {0} as {1}...", T.stringof, name);
    TileRegistry.register!T(name);
    registerTileIOFor!T();
}

void initTileRegistry() {
    TileRegistry = new Registry!Tile();
    registerTile!SandTile();
    registerTile!SandstoneTile();
    registerTile!CoalTile();
    registerTile!CactusPlatformTile();
    registerTile!CactusBaseTile();
    registerTile!CactusTile();
}