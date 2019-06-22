module game.ui.uis.inventory;
import game.ui.elements.uislot;
import game.container;
import game.input;
import polyplex;
import containers.list;

class UIHotbar {
private:
    Container containerRef;

    List!Slot slots;

    bool inventoryMode;

public:
    final void updateRef(ref Container container) {
        this.containerRef = container;
    }

    /++
        Create a new hotbar/player inventory

        container will be watched for updates, etc.
    +/
    this(ref Container container) {
        this.containerRef = container;

        int yOffset = 0;
        foreach(y; 0..container.slotsY) {
            int xOffset = 0;
            foreach(x; 0..container.slotsX) {

                slots ~= new Slot(new Rectangle(
                    16+xOffset+(cast(int)x*48),
                    16+yOffset+(cast(int)y*48),
                    48,
                    48
                ), true, true);

                xOffset += 4;
            }
            yOffset += 4;
        }
    }

    void update() {
        int slot = 0;

        if (Input.IsKeyPressed(Keys.Escape)) inventoryMode = !inventoryMode;

        if (inventoryMode) {
            foreach(y; 0..containerRef.slotsY) {
                foreach(x; 0..containerRef.slotsX) {
                    slots[slot].update(containerRef[x, y]);
                    
                    slot++;
                }
            }
        } else {
            foreach(x; 0..containerRef.slotsX) {
                slots[x].update(containerRef[x, 0]);
            }
        }
    }

    void draw(SpriteBatch spriteBatch, int selected) {
        int slot = 0;
        if (inventoryMode) {
            foreach(y; 0..containerRef.slotsY) {
                foreach(x; 0..containerRef.slotsX) {
                    slots[slot].draw(spriteBatch, containerRef[x, y]);
                    
                    slot++;
                }
            }
        } else {
            foreach(x; 0..containerRef.slotsX) {
                slots[x].draw(spriteBatch, containerRef[x, 0], x == selected ? Color.Red : Color.White);
            }
        }
    }

    void postDraw(SpriteBatch spriteBatch) {
        int slot = 0;
        if (inventoryMode) {
            foreach(y; 0..containerRef.slotsY) {
                foreach(x; 0..containerRef.slotsX) {
                    slots[slot].postDraw(spriteBatch, containerRef[x, y]);
                    
                    slot++;
                }
            }
        } else {
            foreach(x; 0..containerRef.slotsX) {
                slots[x].postDraw(spriteBatch, containerRef[x, 0]);
            }
        }
    }
}