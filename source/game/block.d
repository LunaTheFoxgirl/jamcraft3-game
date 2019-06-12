module game.block;
import polyplex;
import engine.cman;
import game.chunk;
import std.format;
import msgpack;

enum BLOCK_SIZE = 16;

private static Color FGColor;
private static Color BGColor;

static this() {
    FGColor = Color.White;
    BGColor = new Color(169, 169, 169);
}

class Block {
private:
    @nonPacked
    Chunk chunk;

    @nonPacked
    Texture2D texture;


public:
    /// The id of a block
    string blockId;

    /// Position of block in chunk
    @nonPacked
    Vector2i position;

    /// Position of hitbox
    @nonPacked
    Rectangle hitbox;

    this() {

    }

    this(Vector2i position, string blockId, Chunk chunk = null) {
        this.blockId = blockId;
        initBlock(position, chunk);
    }

    @nonPacked
    Vector2i getWorldPosition() {
        return Vector2i(
            (position.X*BLOCK_SIZE)+(chunk.position.X*CHUNK_SIZE*BLOCK_SIZE),
            (position.Y*BLOCK_SIZE)+(chunk.position.Y*CHUNK_SIZE*BLOCK_SIZE));
    }

    void draw(SpriteBatch spriteBatch) {
        spriteBatch.Draw(texture, hitbox, texture.Size, FGColor);
    }

    void drawWall(SpriteBatch spriteBatch) {
        spriteBatch.Draw(texture, hitbox, texture.Size, BGColor);
    }

    void initBlock(Vector2i position, Chunk chunk = null) {
        this.chunk = chunk;
        this.texture = TEXTURES["blocks/block_%s".format(blockId)];

        this.position = position;
        Vector2i wPosition = getWorldPosition();
        this.hitbox = new Rectangle(wPosition.X, wPosition.Y, BLOCK_SIZE, BLOCK_SIZE);
    }
}