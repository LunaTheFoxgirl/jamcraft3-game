module game.container;
import game.itemstack;
import game.item;

/++
    A container is a storage of ItemStacks.
+/
class Container(int _slotsX, int _slotsY) {
private:
    ItemStack[_slotsX][_slotsY] slots;

public:
    /// Amount of slots on the X axis
    const int slotsX = _slotsX;

    /// Amount of slots on the Y axis
    const int slotsY = _slotsY;

    /// Amount of slots in total
    const int slotsTotal = _slotsX*_slotsY;

    /++
        Index the container.
    +/
    ref ItemStack opIndex(uint x, uint y) {
        return slots[y][x];
    }

    /++
        Takes an item from the container at slot

        The container automatically gets updated to reflect the changes.
    +/
    ItemStack takeFrom(uint x, uint y, int count) {
        scope(exit) update();
        return this[x, y].take(count);
    }

    /++
        Puts items in to the container at slot, returned is any leftovers.
        Do not discard output from putIn unless you intend on destroying actual items.

        If the slot is empty, the slot gets filled.
        If the slot has the same type as the input type it will try to fill as much as possible
        Any leftovers will be returned.
        If the slot has a different type; the stacks will be swapped.
    +/
    ItemStack putIn(uint x, uint y, ItemStack stack) {
        if (this[x, y] is null) {
            this[x, y] = stack;
            return null;
        }

        // Fill stack
        if (this[x, y].sharesType(stack)) {
            return this[x, y].combineStack(stack);
        }

        // Swap stacks
        ItemStack oldStack = this[x, y];
        this[x, y] = stack;
        return oldStack;
    }

    ItemStack fitIn(ItemStack stack) {
        foreach(y; 0..slotsY) {
            foreach(x; 0..slotsX) {
                if (this[x, y] is null) {
                    this[x, y] = stack;
                    return null;
                }
                if (this[x, y].sharesType(stack)) {
                    if (this[x, y].getCount() < this[x, y].getItem().getMaxStack()) {
                        this[x, y].combineStack(stack);
                        return null;
                    }
                }
            }
        }
        return stack;
    }

    /++
        Update the container (by removing any empty item stacks)
    +/
    void update() {
        foreach(x; 0..slotsX) {
            foreach(y; 0..slotsY) {
                if (this[x, y] is null) continue;
                if (this[x, y].getCount() <= 0) {
                    this[x, y] = null;
                }
            }
        }
    }
}