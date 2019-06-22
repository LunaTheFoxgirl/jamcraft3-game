module game.ui.elements.uislot;
import polyplex;
import engine.cman;
import game.itemstack;
import game.item;
import game.input;
import game.cursor;

class Slot {
private:
    bool renderOutline;
    bool renderInfo;
    bool selected;
    Rectangle area;

    void delegate() clickCallback;

protected:
    void onUpdate() {}

public:
    this(Rectangle area, bool renderOutline, bool renderInfo) {
        this.renderOutline = renderOutline;
        this.renderInfo = renderInfo;
        setArea(area);
    }

    final void setArea(Rectangle area) {
        this.area = area;
    }

    final void update(ref ItemStack stack) {
        if (area.Intersects(Input.Position)) {

            // Take ALL handler
            if (Input.IsButtonPressed(MouseButton.Left)) {
                if (Cursor.getHeldItems !is null && stack !is null) {
                    if (Cursor.getHeldItems.sharesType(stack)) {
                        ItemStack result = stack.combineStack(Cursor.getHeldItems);
                        Cursor.setHeldItems(result);
                    } else {
                        ItemStack currentCursorStack = Cursor.getHeldItems();
                        Cursor.setHeldItems(stack);
                        stack = currentCursorStack;
                    }
                } else if (Cursor.getHeldItems !is null && stack is null) {
                        stack = Cursor.getHeldItems();
                        Cursor.setHeldItems(null);
                } else if (Cursor.getHeldItems is null && stack !is null) {
                        Cursor.setHeldItems(stack);
                        stack = null;
                }
            }

            // Take HALF handler
            if (Input.IsButtonPressed(MouseButton.Right) && !(stack is null && Cursor.getHeldItems is null)) {
                int splitGet = 1;
                if (stack is null) {
                    splitGet = Cursor.getHeldItems.getCount() == 1 ? 1 : Cursor.getHeldItems.getCount()/2;
                    if (Cursor.getHeldItems !is null) {
                        stack = Cursor.getHeldItems.take(splitGet);
                    }
                } else {
                    splitGet = stack.getCount() == 1 ? 1 : stack.getCount()/2;
                    if (Cursor.getHeldItems is null) {
                        Cursor.setHeldItems(stack.take(splitGet));
                    } else if (Cursor.getHeldItems !is null) {
                        if (Cursor.getHeldItems.sharesType(stack)) {
                            Cursor.getHeldItems.combineStack(stack.take(splitGet));
                        }
                    }
                }
            }

            // Take SINGLE handler
            if (Input.GetScroll != 0 && !(stack is null && Cursor.getHeldItems is null)) {
                if (Input.GetScroll > 0 && Cursor.getHeldItems !is null) {
                    if (stack is null) {
                        stack = Cursor.getHeldItems.take(1);
                    } else {
                        if (Cursor.getHeldItems.sharesType(stack)) {
                            stack.combineStack(Cursor.getHeldItems.take(1));
                        }
                    }
                } else if (Input.GetScroll < 0 && stack !is null) {
                    if (Cursor.getHeldItems is null) {
                         Cursor.setHeldItems(stack.take(1));
                    } else {
                        if (stack.sharesType(Cursor.getHeldItems)) {
                            Cursor.getHeldItems.combineStack(stack.take(1));
                        }
                    }
                }

            }

            Input.interruptMouse();
        }
        onUpdate();
    }

    void draw(SpriteBatch spriteBatch, ItemStack stack, Color slotbg = Color.White) {
        if (renderOutline && selected) {
            spriteBatch.Draw(TEXTURES["ui/ui_selectitem"], area, TEXTURES["ui/ui_selectitem"].Size, Color.White);
        }
        spriteBatch.Draw(TEXTURES["ui/ui_slot"], area, TEXTURES["ui/ui_slot"].Size, slotbg);
        
        if (stack is null) return;
        stack.render(
            spriteBatch, 
            new Rectangle(
                area.X+(area.Width/4), 
                area.Y+(area.Height/4), 
                area.Width/2, 
                area.Width/2));
    }

    void postDraw(SpriteBatch spriteBatch, ItemStack stack) {
        import std.format : format;
        import std.array : split;
        if (stack is null) return;
        if (renderInfo) {
            if (area.Intersects(Input.Position)) {
                string name = stack.getItem().getName() ;
                string desc = stack.getItem().getDescription();

                Vector2 basePos = Cursor.getTextablePosition();
                Vector2 measure = FONTS["fonts/UIFontB"].MeasureString("A");

                spriteBatch.DrawString(FONTS["fonts/UIFontB"], name, basePos, new Color(225, 225, 225), 1f);
                foreach(offset, line; desc.split('\n')) {
                    spriteBatch.DrawString(FONTS["fonts/UIFont"], line, Vector2(basePos.X, basePos.Y+(measure.Y*((offset*2)+2))), new Color(225, 225, 225), 1f);
                }
            }
        }
    }
}