module game.entities.player;
import game.entity;
import game.utils;
import polyplex;

enum PLAYER_SPEED = 2f;
enum PLAYER_JUMP_SPEED = 15f;
enum GRAVITY_CONST = 2.5f;
enum MAX_SPEED = 14f;
enum DRAG_CONST = 0.7f;
enum JUMP_TIMER_START = 10;

struct CollissionData {
    Rectangle collissionArea;
    bool didCollide;
}

class Player : Entity {
private:
    SpriteFlip spriteFlip;
    int jumpTimer;
    bool grounded;

    KeyboardState state;
    Vector2i chunkAtScreen;
    Vector2i blockAtScreen;

    Vector2 feet() {
        return Vector2(
            this.hitbox.Center.X,
            cast(float)this.hitbox.Bottom-0.5f
        );
    }

    Vector2 motion = Vector2(0f, 0f);


    void limitMomentum() {

        if (this.motion.X > MAX_SPEED) this.motion.X = MAX_SPEED;
        if (this.motion.X < -MAX_SPEED) this.motion.X = -MAX_SPEED;

        if (this.motion.Y > MAX_SPEED) this.motion.Y = MAX_SPEED;
        if (this.motion.Y < -MAX_SPEED) this.motion.Y = -MAX_SPEED;

    }

    Vector2i feetBlock(Vector2 offset = Vector2(0, 0)) {
        return Vector2i(cast(int)(feet.X+offset.X), cast(int)(feet.Y+offset.Y)).toBlockPos;
    }

    float calculateAABBCollissionX(Rectangle a, Rectangle b) {
        if (a.Intersects(b) || b.Intersects(a)) {
            if (a.Center.X < b.Center.X) {
                return cast(float)(b.Left-a.Right);
            }
            return cast(float)(b.Right-a.Left);
        }
        return 0.0f;
    }

    float calculateAABBCollissionY(Rectangle a, Rectangle b) {
        if (a.Intersects(b) || b.Intersects(a)) {
            if (a.Center.Y < b.Center.Y) {
                return cast(float)(b.Top-a.Bottom)/4f;
            }
            return cast(float)(b.Bottom-a.Top);
        }
        return 0.0f;
    }

    void handlePhysics() {
        limitMomentum();
        float v;
        Vector2i centerBlock = Vector2i(cast(int)hitbox.Center.X, cast(int)hitbox.Center.Y).toBlockPos;

        position.X += motion.X;
        position.X = Mathf.Round(position.X);
        col: foreach(adjacent; centerBlock.getAdjacent(12, 12)) {
            Block b = world.blockAt(adjacent);
            if (b !is null) {
                Rectangle bAABB = b.hitbox;
                v = calculateAABBCollissionX(this.hitbox, bAABB);
                if (v != 0.0f) {
                    this.motion.X = 0f;
                    this.position.X += v;
                }
            }
        }

        motion.Y += GRAVITY_CONST;
        position.Y += motion.Y;
        grounded = false;
        foreach(adjacent; centerBlock.getAdjacent(12, 12)) {
            Block b = world.blockAt(adjacent);
            if (b !is null) {
                Rectangle bAABB = b.hitbox;
                v = calculateAABBCollissionY(this.hitbox, bAABB);
                if (v < 0) {
                    this.position.Y -= motion.Y;
                    this.motion.Y = 0f;
                    grounded = true;
                }
                if (v > 0) {
                    this.motion.Y = 0.5f;
                    this.position.Y += v;
                }
            }
        }
    }

    void handleMovement() {
        if (state.IsKeyDown(Keys.A)) {
            this.motion.X -= PLAYER_SPEED;
            spriteFlip = SpriteFlip.FlipVertical;
        }

        if (state.IsKeyDown(Keys.D)) {
            this.motion.X += PLAYER_SPEED;
            spriteFlip = SpriteFlip.None;
        }

        this.motion.X *= DRAG_CONST;

        if (state.IsKeyDown(Keys.Space) && grounded) {
            if (jumpTimer == 0) {
                Logger.Info("JUMP!");
                jumpTimer = JUMP_TIMER_START;
            }
        }

        if (jumpTimer > 0) {
            this.motion.Y -= PLAYER_JUMP_SPEED*(1f-(jumpTimer/JUMP_TIMER_START));
            jumpTimer--;
        }

        handlePhysics();
    }

public:
    this(World world) {
        super(world, Vector2(0f, 0f));
    }

    override Rectangle hitbox() {
        return new Rectangle(cast(int)position.X, cast(int)position.Y, 32, 64);
    }

    override void update(GameTimes gameTime) {
        blockAtScreen = world.getBlockAtScreen(Mouse.Position);
        chunkAtScreen = blockAtScreen.blockPosToChunkPos;
        state = Keyboard.GetState();

        handleMovement();

        if (Mouse.GetState().IsButtonPressed(MouseButton.Right)) {
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

        if (Mouse.GetState().IsButtonPressed(MouseButton.Left)) {
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
        world.camera.Position = this.hitbox.Center;
        world.camera.Zoom = 1f; //2f;
    }

    override void draw(SpriteBatch spriteBatch) {
        spriteBatch.Draw(TEXTURES["blocks/block_sand"], new Rectangle(blockAtScreen.X*BLOCK_SIZE, blockAtScreen.Y*BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE), TEXTURES["blocks/block_sand"].Size, Color.Blue);
        spriteBatch.Draw(TEXTURES["entities/entity_player"], this.hitbox, TEXTURES["entities/entity_player"].Size, Color.White, spriteFlip);
    }
}