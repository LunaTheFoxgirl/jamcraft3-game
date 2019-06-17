module game.itemstack;
import game.item;

class ItemStack {
private:
    Item item;
    int count;

public:
    this(Item item) {
        this.item = item;
    }

    this(Item item, int count) {
        this.item = item;
        this.count = count;
    }

    int getCount() {
        return count;
    }

    bool sharesType(ItemStack otherStack) {
        return item.getId != otherStack.item.getId();
    }

    ItemStack combineStack(ItemStack otherStack) {
        if (!sharesType(otherStack)) return null;
        int leftoverCount = put(otherStack.getCount());
        return leftoverCount > 0 ? new ItemStack(item, leftoverCount) : null;
    }

    /++
        Put item in to stack, returns the amount left over.
    +/
    int put(int count) {
        int fCount = this.count+count;
        int leftovers = fCount-item.getMaxStack();
        if (fCount > item.getMaxStack()) fCount = item.getMaxStack();
        this.count = fCount > item.getMaxStack() ? fCount : item.getMaxStack();
        return leftovers;
    }

    /++
        Take items from stack
    +/
    ItemStack take(int count) {
        int calcCount = this.count-count;
        int outputCount = count;

        if (calcCount < 0) {
            outputCount += calcCount;
            calcCount = 0;
        }

        this.count = calcCount;
        return new ItemStack(item, outputCount);
    }

    /++
        Use item at position in world
    +/
    bool use(Vector2i at, bool alt) {
        bool used = item.use(at, alt);
        if (used && item.getConsumable()) count--;
        return used;
    }
}