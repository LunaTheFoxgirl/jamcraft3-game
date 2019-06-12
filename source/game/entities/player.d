module game.entities.player;
import game.entity;
import game.utils;
import polyplex;

enum PLAYER_SPEED = 10f;

class Player : Entity {
private:
    KeyboardState state;
    Vector2i chunkAtScreen;
    Vector2i blockAtScreen;

public:
    this(World world) {
        super(world, Vector2(0f, 0f));
    }

    override Rectangle hitbox() {
        return new Rectangle(cast(int)position.X, cast(int)position.Y, 16, 32);
    }

    override void update(GameTimes gameTime) {
        blockAtScreen = world.getBlockAtScreen(Mouse.Position);
        chunkAtScreen = blockAtScreen.blockPosToChunkPos;
        state = Keyboard.GetState();

        if (state.IsKeyDown(Keys.D)) {
            this.position.X += PLAYER_SPEED;
        }
        if (state.IsKeyDown(Keys.A)) {
            this.position.X -= PLAYER_SPEED;
        }
        if (state.IsKeyDown(Keys.W)) {
            this.position.Y -= PLAYER_SPEED;
        }
        if (state.IsKeyDown(Keys.S)) {
            this.position.Y += PLAYER_SPEED;
        }

        if (Mouse.GetState().IsButtonPressed(MouseButton.Left)) {
            Chunk chunk = world[chunkAtScreen.X, chunkAtScreen.Y];
            Vector2i mBlockPos = blockAtScreen.wrapBlockPos;

            Vector2i blockPos = Vector2i(cast(int)mBlockPos.X, cast(int)mBlockPos.Y);
            if (chunk !is null) {
                if (chunk.blocks[blockPos.X][blockPos.Y] !is null) {
                    Logger.Info("Destroy! @ {0} in {1}", blockPos, chunk.position);
                    chunk.blocks[blockPos.X][blockPos.Y] = null;
                    chunk.modified = true;
                }
            }
        }

        if (Mouse.GetState().IsButtonPressed(MouseButton.Right)) {
            Chunk chunk = world[chunkAtScreen.X, chunkAtScreen.Y];
            Vector2i blockPos = blockAtScreen.wrapBlockPos;
            if (chunk !is null) {
                Logger.Info("Place! @ {0} in {1}", blockPos, chunk.position);
                if (chunk.blocks[blockPos.X][blockPos.Y] is null) {
                    chunk.blocks[blockPos.X][blockPos.Y] = new Block(blockPos, "sand", chunk);
                    chunk.modified = true;
                }
            }
        }
        world.camera.Position = this.position;
        world.camera.Zoom = 1f; //2f;
    }

    override void draw(SpriteBatch spriteBatch) {
        spriteBatch.Draw(TEXTURES["blocks/block_sand"], new Rectangle(blockAtScreen.X*BLOCK_SIZE, blockAtScreen.Y*BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE), TEXTURES["blocks/block_sand"].Size, Color.Blue);
    }
}