module game.items;
public import game.item;
public import game.items.itemtile;
public import game.items.itemcactus;
import engine.registry;
import polyplex;

__gshared static Registry!Item ItemRegistry;

Item createItem(ref Registry!Item ext, string id, string subId = null) {
    Item t = ext.createNew(id);
    return t(subId);
}

private void registerItem(T)() if (is(T : Item)) {
    T tx = new T;
    string name = tx.getId;
    Logger.Info("[ItemRegistry] Registering {0} as {1}...", T.stringof, name);
    ItemRegistry.register!T(name);
}

void initItemRegistry() {
    ItemRegistry = new Registry!Item();
    registerItem!ItemTile();
    registerItem!ItemCactus();
}