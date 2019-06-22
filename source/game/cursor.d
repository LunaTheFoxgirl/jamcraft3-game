module game.cursor;
import game.itemstack;
import game.input;
import polyplex;
import engine.cman;
import game.items;

__gshared GameCursorImpl Cursor;

class GameCursorImpl {
private:
    ItemStack heldItemStack;
    Vector2 textablePosition;

public:

    final ref ItemStack getHeldItems() {
        return heldItemStack;
    }

    final void setHeldItems(ItemStack stack) {
        this.heldItemStack = stack;
    }

    /++
        Returns a position where text can be displayed properly
    +/
    Vector2 getTextablePosition() {
        Vector2 mpos = Input.Position();
        if (heldItemStack !is null) return Vector2(mpos.X+24, mpos.Y+64);
        return Vector2(mpos.X+24, mpos.Y+24);
    }

    void update() {
        if (heldItemStack !is null) {
            if (heldItemStack.getCount() <= 0) heldItemStack = null;
        }
    }

    void render(SpriteBatch spriteBatch) {
        Vector2 mpos = Input.Position();
        spriteBatch.Draw(
            TEXTURES["ui/ui_cursor"], 
            new Rectangle(cast(int)mpos.X, cast(int)mpos.Y, 24, 24), 
            TEXTURES["ui/ui_cursor"].Size, 
            Color.White);

        if (heldItemStack !is null) 
            heldItemStack.render(
                spriteBatch, 
                new Rectangle(
                    cast(int)mpos.X+24, 
                    cast(int)mpos.Y+24, 
                    24, 
                    24));
    }
}