module game.item;
import polyplex;
import msgpack;
import engine.cman;
import game.entity;

class Item {
private:

    string id;

    string subId;

    @nonPacked
    bool hasSubTypes = false;

    @nonPacked
    ushort maxStack = 999;
    
    @nonPacked
    bool consumable;

    @nonPacked
    string texture;

    @nonPacked
    string name = "Unnamed Item";

    @nonPacked
    string description = "A fancy description goes here!";

    @nonPacked
    int useTime = 25;

    Texture2D getTexture() {
        return TEXTURES["items/item_"~texture];
    }

protected:
    final void setSubId(string subId) {
        if (!hasSubTypes) return;
        this.subId = subId;
    }

    final void setName(string name) {
        this.name = name;
    }

    final void setDescription(string description) {
        this.description = description;
    }

    final void setUseTime(int useTime) {
        this.useTime = useTime;
    }

    final void setHasSubTypes(bool hasSubTypes) {
        this.hasSubTypes = hasSubTypes;
        if (!hasSubTypes) {
            subId = null;
        }
    }

    final void setTexture(string name) {
        this.texture = name;
    }

    final void setMaxStack(ushort size) {
        maxStack = size;
    }

    final void setConsumable(bool consumable) {
        this.consumable = consumable;
    }

    bool onUse(Entity user, Vector2i at, bool alt) {
        return false;
    }

    void onRender(Rectangle area, SpriteBatch spriteBatch) {
        spriteBatch.Draw(getTexture(), area, getTexture().Size, Color.White);
    }

    void onInit(string subId) { }

public:
    this(string id) {
        this.id = id;
    }
    
    final string getId() {
        if (subId !is null) return id~":"~subId;
        else return id;
    }

    final string getSubId() {
        return subId;
    }

    final ushort getMaxStack() {
        return maxStack;
    }

    final bool getConsumable() {
        return consumable;
    }

    final string getTextureName() {
        return texture;
    }

    final string getName() {
        return name;
    }

    final string getDescription() {
        return description;
    }

    final int getUseTime() {
        return useTime;
    }

    final bool use(Entity user, Vector2i at, bool alt) {
        return onUse(user, at, alt);
    }

    final void render(Rectangle area, SpriteBatch spriteBatch) {
        onRender(area, spriteBatch);
    }

    final Item opCall(string subId) {
        onInit(subId);
        return this;
    }
}