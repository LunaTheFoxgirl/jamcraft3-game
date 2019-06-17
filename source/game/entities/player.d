module game.entities.player;
import game.entity;
import game.utils;
import game.tiles;
import game.container;
import game.items;
import game.itemstack;
import engine.music;
import polyplex;
import config;

struct CollissionData {
    Rectangle collissionArea;
    bool didCollide;
}

struct PlayerStats {
    int swingSpeedBreak;
    int swingSpeedPlace;
    int reach = 4;
    int pickPower = 1;
}

class Player : Entity {
private:
    /++
        INVENTORY
    +/
    Container!(10, 6) inventory;
    int selectedSlot = 0;


    /++
        INPUT HANDLING
    +/
    KeyboardState state;
    MouseState mouseState;


    /++
        SPRITE STATE
    +/
    SpriteFlip spriteFlip;




    /++
        PLAYER OPTIONS
    +/
    PlayerStats stats;
    



    /++
        POSITIONING AND MOVEMENT
    +/
    Vector2i chunkAtScreen;
    Vector2i tileAtScreen;
    Vector2 motion = Vector2(0f, 0f);
    int jumpTimer;
    int actionTimer;
    bool grounded;

    Vector2 feet() {
        return Vector2(
            this.hitbox.Center.X,
            cast(float)this.hitbox.Bottom-0.5f
        );
    }

    Vector2i feetBlock(Vector2 offset = Vector2(0, 0)) {
        return Vector2i(cast(int)(feet.X+offset.X), cast(int)(feet.Y+offset.Y)).toTilePos;
    }




    /++
        UTILITY
    +/

    void limitMomentum() {

        if (this.motion.X > MAX_SPEED) this.motion.X = MAX_SPEED;
        if (this.motion.X < -MAX_SPEED) this.motion.X = -MAX_SPEED;

        if (this.motion.Y > MAX_SPEED) this.motion.Y = MAX_SPEED;
        if (this.motion.Y < -MAX_SPEED) this.motion.Y = -MAX_SPEED;

    }

    void handlePhysics() {
        limitMomentum();
        float v;
        Vector2i centerTile = Vector2i(cast(int)hitbox.Center.X, cast(int)hitbox.Center.Y).toTilePos;

        position.X += motion.X;
        position.X = Mathf.Round(position.X);
        col: foreach(adjacent; centerTile.getAdjacent(12, 12)) {
            Tile b = world.tileAt(adjacent);
            if (b !is null && b.isCollidable()) {
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
            if (!state.IsKeyDown(Keys.Space) && jumpTimer <= JUMP_TIMER_START/2) jumpTimer = 0;
            jumpTimer--;
            
        }
        position.Y += motion.Y;
        grounded = false;
        foreach(adjacent; centerTile.getAdjacent(12, 12)) {
            Tile b = world.tileAt(adjacent);
            if (b !is null && b.isCollidable()) {
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

    bool attackBlock(Vector2i at, bool wall) {
        chunkAtScreen = at.tilePosToChunkPos;
        Chunk chunk = world[chunkAtScreen.X, chunkAtScreen.Y];
        Vector2i mBlockPos = at.wrapTilePos;

        Vector2i tilePos = Vector2i(cast(int)mBlockPos.X, cast(int)mBlockPos.Y);
        if (chunk !is null) {
            return chunk.attackTile(tilePos, stats.pickPower, wall);
        }
        return false;
    }

    bool withinReach(Vector2i position) {
        return (position.Distance(hitbox.Center.toTilePos) <= stats.reach);
    }

    bool readyForAction() {
        return actionTimer == 0;
    }



    /++
        UPDATE HANDLER FUNCTIONS
    +/

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
            if (jumpTimer <= 0) {
                jumpTimer = JUMP_TIMER_START;
            }
        }

        handlePhysics();
    }

    void handleInteraction() {
        tileAtScreen = world.getTileAtScreen(Mouse.Position);

        if (state.IsKeyDown(Keys.LeftShift)) {
            float scroll = mouseState.Position.Z/20;
            world.camera.Zoom += scroll;
            if (world.camera.Zoom < 0.9f) {
                world.camera.Zoom = 0.9f;
            }
            if (world.camera.Zoom > 2.5f) {
                world.camera.Zoom = 2.5f;
            }
        }

        // Ingame action start here, we have timeouts for those.
        if (!readyForAction) return;
        if (mouseState.Position.Z == -1 || mouseState.Position.Z == 1) {
            selectedSlot += cast(uint)mouseState.Position.Z;
            if (selectedSlot < 0) {
                selectedSlot = 9;
            }
            selectedSlot %= 10;
            Item item = inventory[selectedSlot, 0] !is null ? inventory[selectedSlot, 0].getItem() : null;
            string name = item !is null ? item.getName() : "Bare Hands";
            string description = item !is null ? item.getDescription() : "You can barely dig with these...";
            Logger.Info("Changed to hotbar slot {0} ({1}: {2})...", selectedSlot, name, description);
            actionTimer = 5;
        }

        // Using items requires them to be in your arm's reach.
        if (!withinReach(tileAtScreen)) return;
        if (mouseState.IsButtonPressed(MouseButton.Right) || mouseState.IsButtonPressed(MouseButton.Left)) {
            bool alt = mouseState.IsButtonPressed(MouseButton.Right);
            if (inventory[selectedSlot, 0] !is null) {
                if (inventory[selectedSlot, 0].use(this, tileAtScreen, alt)) {
                    actionTimer = inventory[selectedSlot, 0].getItem().getUseTime();
                }
            } else {
                attackBlock(tileAtScreen, alt);
                actionTimer = stats.swingSpeedBreak;
            }
        }
        
    }

    void handleMusic() {
        import config;
        if (hitbox.Center.toTilePos.Y > H_HEIGHT_LIMIT) {
            MusicManager.play("underground");
        } else {
            MusicManager.play("day");
        }
    }

public:
    this(World world) {
        super(world, Vector2(0f, 0f));
        inventory = new Container!(10, 6)();
        inventory[1, 0] = new ItemStack(new ItemTile()("sandstone"), 999);
        inventory[2, 0] = new ItemStack(new ItemTile()("sand"), 999);
        inventory[3, 0] = new ItemStack(new ItemTile()("cactus"), 999);
        inventory[4, 0] = new ItemStack(new ItemTile()("cactusbase"), 1);
        inventory[5, 0] = new ItemStack(new ItemTile()("glowsand"), 999);
    }

    override Rectangle hitbox() {
        return new Rectangle(cast(int)position.X+8, cast(int)position.Y+8, 16, 64-8);
    }

    Rectangle renderbox() {
        return new Rectangle(cast(int)position.X, cast(int)position.Y, 32, 64);
    }

    override void update(GameTimes gameTime) {
        state = Keyboard.GetState();
        mouseState = Mouse.GetState();
        if (actionTimer > 0) {
            actionTimer--;
        }


        handleMovement();
        handleInteraction();
        handleMusic();

        inventory.update();

        world.camera.Position = this.hitbox.Center;
    }

    override void draw(SpriteBatch spriteBatch) {
        spriteBatch.Draw(TEXTURES["entities/entity_player"], this.renderbox, TEXTURES["entities/entity_player"].Size, Color.White, spriteFlip);
    }

    void renderInvCircle(SpriteBatch spriteBatch, Rectangle rect, int i) {
        int wEx = rect.Width/2;
        int hEx = rect.Height/2;
        Rectangle xRect = new Rectangle(rect.X-wEx, rect.Y-hEx, rect.Width*2, rect.Height*2);
        spriteBatch.Draw(TEXTURES["ui/ui_selectitem"], xRect, TEXTURES["ui/ui_selectitem"].Size, Color.White);
        if (inventory[i, 0] !is null) inventory[i, 0].getItem().render(rect, spriteBatch);
    }

    override void drawAfter(SpriteBatch spriteBatch) {
        int offset = 16;
        foreach(i; 0..10) {
            if (i == selectedSlot) {
                renderInvCircle(spriteBatch, new Rectangle(offset-2, 16-2, 32+4, 32+4), i);
            } else {
                renderInvCircle(spriteBatch, new Rectangle(offset, 16, 32, 32), i);
            }
            offset += 64;
        }
        //spriteBatch.Draw(TEXTURES["tiles/tile_sand"], new Rectangle(tileAtScreen.X*BLOCK_SIZE, tileAtScreen.Y*BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE), TEXTURES["tiles/tile_sand"].Size, Color.Blue);
    }
}