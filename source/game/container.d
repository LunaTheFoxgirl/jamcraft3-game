module game.container;
import game.itemstack;
import game.item;
import msgpack;
import polyplex;

/++
    A container is a storage of ItemStacks.
+/
class Container {
private:
    ItemStack[][] slots;

public:
    /// Amount of slots on the X axis
    @nonPacked
    immutable size_t slotsX;

    /// Amount of slots on the Y axis
    @nonPacked
    immutable size_t slotsY;

    /// Amount of slots in total
    @nonPacked
    immutable size_t slotsTotal;

    this(size_t sizeX, size_t sizeY) {
        slots = new ItemStack[][](sizeX, sizeY);
        slotsX = sizeX;
        slotsY = sizeY;
        slotsTotal = slotsX*slotsY;
    }

    /++
        Index the container.
    +/
    ref ItemStack opIndex(size_t x, size_t y) {
        return slots[x][y];
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

void handlePackingContainer(ref Packer packer, ref Container container) {
    packer.beginMap(2);
    packer.pack("size");
    packer.packArray(container.slotsX, container.slotsY);

    packer.pack("contents");
    packer.beginArray(container.slotsX*container.slotsY);
    foreach(y; 0..container.slotsY) {
        foreach(x; 0..container.slotsX) {
            if (container[x, y] is null) {
                packer.pack(null);
                continue;
            }
            Item item = container[x, y].getItem();
            packer.packArray(item.getId(), item.getSubId(), container[x, y].getCount());
        }
    }
}

void handleUnpackingContainer(ref Unpacker unpacker, ref Container container) {
    import game.items;
    import std.stdio;
    string region;
    unpacker.beginMap();
    unpacker.unpack(region);

    size_t sizeX;
    size_t sizeY;
    unpacker.unpackArray(sizeX, sizeY);
    container = new Container(sizeX, sizeY);

    unpacker.unpack(region);
    size_t arraySize = unpacker.beginArray();
    foreach(y; 0..sizeY) {
        foreach(x; 0..sizeX) {
            size_t size = unpacker.beginArray();
            if (size == 0) continue;

            string id;
            string subId;
            int count;
            unpacker.unpack(id);
            unpacker.unpack(subId);
            unpacker.unpack(count);

            Item item = ItemRegistry.createItem(id, subId);
            container[x, y] = new ItemStack(item, count);
        }
    }
}

void registerContainerIO() {
    registerPackHandler!(Container, handlePackingContainer);
    registerUnpackHandler!(Container, handleUnpackingContainer);
}