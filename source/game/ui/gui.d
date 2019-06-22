module game.ui.gui;
import polyplex;
import containers.list;

class GUI {
    GUIElement root;

    void update() {
        root.update();
    }

    void draw(SpriteBatch spriteBatch) {
        root.draw(spriteBatch);
    }

    void postDraw(SpriteBatch spriteBatch) {
        root.postDraw(spriteBatch);
    }
}

class GUIElement {
protected:
    GUIElement parent;
    List!GUIElement children;
    Vector2 position;

    abstract void onUpdate();
    abstract void onDraw(SpriteBatch spriteBatch);
    abstract void onPostDraw(SpriteBatch spriteBatch);

    Vector2 getRenderPosition() {
        if (parent is null) return position;
        return parent.position + position;
    }
public:
    final void update() {
        this.onUpdate();
    }

    final void draw(SpriteBatch spriteBatch) {
        this.onDraw(spriteBatch);
    }

    final void postDraw(SpriteBatch spriteBatch) {
        this.onPostDraw(spriteBatch);
    }
}