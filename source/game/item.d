module game.item;
import polyplex;
import msgpack;
import engine.cman;

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
    string name;

    @nonPacked
    string description;

    Texture2D getTexture() {
        return TEXTURES["items/item_"~texture];
    }

protected:
    void setSubId(string subId) {
        if (!hasSubTypes) return;
        this.subId = subId;
    }

    void setName(string name) {
        this.name = name;
    }

    void setDescription(string description) {
        this.description = description;
    }

    void setHasSubTypes(bool hasSubTypes) {
        this.hasSubTypes = hasSubTypes;
        if (!hasSubTypes) {
            subId = null;
        }
    }

    void setTexture(string name) {
        this.texture = name;
    }

    void setMaxStack(ushort size) {
        maxStack = size;
    }

    void setConsumable(bool consumable) {
        this.consumable = consumable;
    }

    bool onUse(Vector2i at, bool alt) {
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

    final bool use(Vector2i at, bool alt) {
        return onUse(at, alt);
    }

    final void render(Rectangle area, SpriteBatch spriteBatch) {
        onRender(area, spriteBatch);
    }

    final Item opCall(string subId) {
        onInit(subId);
        return this;
    }
}