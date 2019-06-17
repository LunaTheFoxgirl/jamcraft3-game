module game.items;
import game.item;
import engine.registry;

__gshared static Registry!Item ItemRegistry;

Item createItem(string id, string subId = null) {
    Item t = ItemRegistry.createNew(id);
    return t;
}

private void registerItem(T)() if (is(T : Item)) {
    T tx = new T;
    string name = tx.getId;
    Logger.Info("[ItemRegistry] Registering {0} as {1}...", T.stringof, name);
    ItemRegistry.register!T(name);
}

void initRegistry() {
    ItemRegistry = new Registry!Item();
}