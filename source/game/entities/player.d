module game.entities.player;
import game.entity;
import game.utils;
import game.tiles;
import polyplex;

enum PLAYER_SPEED = 1.8f;
enum PLAYER_JUMP_SPEED = 1f;
enum GRAVITY_CONST = 1.5f;
enum MAX_SPEED = 14f;
enum DRAG_CONST = 0.7f;


enum JUMP_TIMER_START = 10;

struct CollissionData {
    Rectangle collissionArea;
    bool didCollide;
}

class Player : Entity {
private:

    int breakSpeed = 4;
    int placeSpeed = 10;

    SpriteFlip spriteFlip;
    int jumpTimer;
    int actionTimer;
    bool grounded;

    KeyboardState state;
    Vector2i chunkAtScreen;
    Vector2i tileAtScreen;

    int pickPower = 1;

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
        return Vector2i(cast(int)(feet.X+offset.X), cast(int)(feet.Y+offset.Y)).toTilePos;
    }

    void handlePhysics() {
        limitMomentum();
        float v;
        Vector2i centerTile = Vector2i(cast(int)hitbox.Center.X, cast(int)hitbox.Center.Y).toTilePos;

        position.X += motion.X;
        position.X = Mathf.Round(position.X);
        col: foreach(adjacent; centerTile.getAdjacent(12, 12)) {
            Tile b = world.tileAt(adjacent);
            if (b !is null) {
                Rectangle bAABB = b.hitbox;
                v = calculateAABBCollissionX(this.hitbox, bAABB);
                if (v != 0.0f) {
                    this.motion.X = 0f;
                    this.position.X += v;
                }
            }
        }

        if (jumpTimer <= 0) {
            motion.Y += GRAVITY_CONST;
        } else {
            this.motion.Y -= Mathf.Lerp(0, PLAYER_JUMP_SPEED, (1f-(jumpTimer/JUMP_TIMER_START)));
            jumpTimer--;
        }
        position.Y += motion.Y;
        grounded = false;
        foreach(adjacent; centerTile.getAdjacent(12, 12)) {
            Tile b = world.tileAt(adjacent);
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
                jumpTimer = JUMP_TIMER_START;
            }
        }

        handlePhysics();
    }

    bool attackBlock(Vector2i at, bool wall) {
        chunkAtScreen = at.tilePosToChunkPos;
        Chunk chunk = world[chunkAtScreen.X, chunkAtScreen.Y];
        Vector2i mBlockPos = at.wrapTilePos;

        Vector2i tilePos = Vector2i(cast(int)mBlockPos.X, cast(int)mBlockPos.Y);
        if (chunk !is null) {
            return chunk.attackTile(tilePos, pickPower, wall);
        }
        return false;
    }

    bool placeTile(T)(T tile, Vector2i at, bool isWall) {
        // Get the chunk where the tile should be placed
        chunkAtScreen = at.tilePosToChunkPos;
        Chunk chunk = world[chunkAtScreen.X, chunkAtScreen.Y];

        // Calculate the tilepos within
        Vector2i tilePos = at.wrapTilePos;

        // Handle wall case
        if (isWall)  return chunk.placeWall(tile, tilePos, pickPower*2);
        
        // Get tile position in pixels as a rectangle via default collission
        Vector2i px = at.toPixels;
        Rectangle tileBounds = getDefaultHB(px);

        // If the tile would be in the way cancel.
        if (tileBounds.Intersects(this.hitbox)) return false;

        // Try to place tile
        return chunk.placeTile(tile, tilePos, pickPower*2);
    }

    void handleInteraction() {
        tileAtScreen = world.getTileAtScreen(Mouse.Position);
        if (actionTimer == 0) {
            bool wall = state.IsKeyDown(Keys.LeftShift);
            if (Mouse.GetState().IsButtonPressed(MouseButton.Right)) {
                placeTile(new GlowsandTile(), tileAtScreen, wall);
                actionTimer = placeSpeed;
                return;
            }

            if (Mouse.GetState().IsButtonPressed(MouseButton.Left)) {
                if (attackBlock(tileAtScreen, wall)) {
                    actionTimer = breakSpeed;
                    return;
                }
            }
        }
    }

public:
    this(World world) {
        super(world, Vector2(0f, 0f));
    }

    override Rectangle hitbox() {
        return new Rectangle(cast(int)position.X+8, cast(int)position.Y+8, 16, 64-8);
    }

    Rectangle renderbox() {
        return new Rectangle(cast(int)position.X, cast(int)position.Y, 32, 64);
    }

    override void update(GameTimes gameTime) {
        state = Keyboard.GetState();
        if (actionTimer > 0) {
            actionTimer--;
        }

        handleMovement();
        handleInteraction();
        world.camera.Position = this.hitbox.Center;
        float scroll = Mouse.GetState().Position.Z/20;

        world.camera.Zoom += scroll;
        if (world.camera.Zoom < 0.9f) {
            world.camera.Zoom = 0.9f;
        }
        if (world.camera.Zoom > 2.5f) {
            world.camera.Zoom = 2.5f;
        }
    }

    override void draw(SpriteBatch spriteBatch) {
        spriteBatch.Draw(TEXTURES["entities/entity_player"], this.renderbox, TEXTURES["entities/entity_player"].Size, Color.White, spriteFlip);
    }

    override void drawAfter(SpriteBatch spriteBatch) {
        //spriteBatch.Draw(TEXTURES["tiles/tile_sand"], new Rectangle(tileAtScreen.X*BLOCK_SIZE, tileAtScreen.Y*BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE), TEXTURES["tiles/tile_sand"].Size, Color.Blue);
    }
}