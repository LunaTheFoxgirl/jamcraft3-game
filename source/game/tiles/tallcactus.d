module game.tiles.tallcactus;
import game.tiles;
import polyplex;
import game.itemstack;
import game.items;
import config;

class TallCactusTile : Tile {
public:
    this() {
        super("tallcactus");
        setName("Tall Cactus");
        setDescription("You really shouldn't be holding this...");
        setTexture("cactuslong");
        setStrength(1);
        setHealth(15);
        setCollidable(false);
    }

    override void onInit(Vector2i position, bool wall, Chunk chunk) {
        super.onInit(position, wall, chunk);
        // Set up rendering and hitbox
        Texture2D tex = getTexture();
        Vector2i worldPos = this.getWorldPositionPixels();
        setHitbox(new Rectangle(worldPos.X, (worldPos.Y-tex.Height)+TILE_SIZE, tex.Width, tex.Height));
        setRenderbox(new Rectangle(worldPos.X, (worldPos.Y-tex.Height)+TILE_SIZE, tex.Width, tex.Height));
    }

    override ItemStack getDrops() {
        return new ItemStack(new ItemCactus(), 15);
    }

    override void onDraw(SpriteBatch spriteBatch, bool wall) {
        // Draw
        spriteBatch.Draw(
            getTexture(), 
            getRenderBoxNoFX(), 
            getTexture().Size, 
            getHitScaleFX()/20f,
            Vector2(
                getTexture().Size.Center.X, 
                getTexture().Height), 
            wall ? BGColor : FGColor);
    }
}