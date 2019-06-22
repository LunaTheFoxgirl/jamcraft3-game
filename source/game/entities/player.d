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
import game.ui.uis.inventory;
import game.input;
import game.cursor;

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
    Container inventory;
    int selectedSlot = 0;
    UIHotbar hotbar;


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
    int jumpTimer;
    int actionTimer;
    bool grounded;

    /++
        UTILITY
    +/

    bool attackBlock(Vector2i at, bool wall) {
        chunkAtScreen = at.tilePosToChunkPos;
        Chunk chunk = world[chunkAtScreen.X, chunkAtScreen.Y];
        Vector2i mBlockPos = at.wrapTilePos;

        Vector2i tilePos = Vector2i(cast(int)mBlockPos.X, cast(int)mBlockPos.Y);
        if (chunk !is null) {
            return chunk.attackTile(this, tilePos, stats.pickPower, wall);
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
            this.momentum.X -= PLAYER_SPEED;
            spriteFlip = SpriteFlip.FlipVertical;
        }

        if (state.IsKeyDown(Keys.D)) {
            this.momentum.X += PLAYER_SPEED;
            spriteFlip = SpriteFlip.None;
        }

        if (state.IsKeyDown(Keys.S)) {
            this.momentum.Y += PLAYER_SPEED;
        }

        this.momentum.X *= DRAG_CONST;

        if (state.IsKeyDown(Keys.Space) && grounded) {
            if (jumpTimer <= 0) {
                jumpTimer = JUMP_TIMER_START;
            }
        }

        handlePhysics();
    }


    void handlePhysics() {
        if (jumpTimer <= 0) this.momentum.Y += GRAVITY_CONST;
        else {
            this.momentum.Y *= DRAG_CONST;
            this.momentum.Y -= Mathf.Lerp(0, PLAYER_JUMP_SPEED, (1f-(jumpTimer/JUMP_TIMER_START)));
            if (!state.IsKeyDown(Keys.Space) && jumpTimer <= JUMP_TIMER_START/1.2) jumpTimer = 0;
            jumpTimer--;
        }
        this.limitMomentum(MAX_SPEED);

        handleCollissionX();
        handleCollissionY();
    }

    /// Collission and response on X axis
    void handleCollissionX() {
        scope(exit) this.updateHitbox();

        // Iterate through precision of collission
        foreach(i; 0..PLAYER_COL_PRECISION) {

            float mx = (momentum.X/PLAYER_COL_PRECISION);

            // Temporary position based on momentum derived from precision
            this.position.X += mx;
            this.updateHitbox();

            int tries = 0;
            Vector2 t = collidesRect(world, this, hitbox, Vector2(mx, 0));
            while(t.X != 0) {
                this.position.X += t.X;
                this.momentum.X = 0;
                this.updateHitbox();
                if (tries > TILE_SIZE) break;

                // Next cycle
                t = collidesRect(world, this, hitbox, Vector2(mx, 0));
                tries++;
            }
        }
    }

        /// Collission and response on X axis
    void handleCollissionY() {
        scope(exit) this.updateHitbox();

        grounded = false;

        // Iterate through precision of collission
        foreach(i; 0..PLAYER_COL_PRECISION) {

            // Temporary position based on momentum derived from precision
            float my = (momentum.Y/PLAYER_COL_PRECISION);
            this.position.Y += my;
            this.updateHitbox();

            int tries = 0;
            Vector2 t = collidesRect(world, this, hitbox, Vector2(0, my), 8);
            while(t.Y != 0) {
                this.position.Y += t.Y;
                if (momentum.Y > 0) {
                    grounded = true;
                }
                this.momentum.Y = 0;
                this.updateHitbox();
                if (tries > TILE_SIZE) break;

                // Next cycle
                t = collidesRect(world, this, hitbox, Vector2(0, my), 8);
                tries++;
            }
        }
    }

    void handleInteraction() {
        tileAtScreen = world.getTileAtScreen(Mouse.Position);

        if (Input.IsKeyDown(Keys.LeftShift)) {
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

        // Avoid zoom interfereing with hotbar switching
        if (!Input.IsKeyDown(Keys.LeftShift)) {
            if (Input.GetScroll != 0) {
                selectedSlot += cast(uint)mouseState.Position.Z;
                if (selectedSlot < 0) {
                    selectedSlot = 9;
                }
                selectedSlot %= 10;
                Item item = inventory[selectedSlot, 0] !is null ? inventory[selectedSlot, 0].getItem() : null;
                actionTimer = 3;
            }
        }

        // Number keys for switching hotbar slot.
        if (state.IsKeyDown(Keys.One))   selectedSlot = 0;
        if (state.IsKeyDown(Keys.Two))   selectedSlot = 1;
        if (state.IsKeyDown(Keys.Three)) selectedSlot = 2;
        if (state.IsKeyDown(Keys.Four))  selectedSlot = 3;
        if (state.IsKeyDown(Keys.Five))  selectedSlot = 4;
        if (state.IsKeyDown(Keys.Six))   selectedSlot = 5;
        if (state.IsKeyDown(Keys.Seven)) selectedSlot = 6;
        if (state.IsKeyDown(Keys.Eight)) selectedSlot = 7;
        if (state.IsKeyDown(Keys.Nine))  selectedSlot = 8;
        if (state.IsKeyDown(Keys.Zero))  selectedSlot = 9;

        // Using items requires them to be in your arm's reach.
        if (!withinReach(tileAtScreen)) return;
        if (Input.IsButtonDown(MouseButton.Right) || Input.IsButtonDown(MouseButton.Left)) {
            bool alt = Input.IsButtonDown(MouseButton.Right);
            if (Cursor.getHeldItems() !is null) {
                if (Cursor.getHeldItems().use(this, tileAtScreen, alt)) {
                    actionTimer = Cursor.getHeldItems().getItem().getUseTime();
                }
            } else {
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
        super(world, Vector2(0f, 0f), new Rectangle(8, 8, 16, 64-8));
        inventory = new Container(10, 6);

        hotbar = new UIHotbar(inventory);

        // static foreach(i; 0..10) {
        //     slots[i].setClickCallback(() {
        //         selectedSlot = i;
        //         Input.interruptMouse();
        //     });
        // }

        // inventory[0, 0] = new ItemStack(new ItemTile()("sandstone"), 999);
        // inventory[1, 0] = new ItemStack(new ItemTile()("sand"), 999);
        // inventory[2, 0] = new ItemStack(new ItemTile()("cactus"), 999);
        // inventory[3, 0] = new ItemStack(new ItemTile()("cactusbase"), 8);
        // inventory[4, 0] = new ItemStack(new ItemTile()("cactusplatform"), 999);
        // inventory[5, 0] = new ItemStack(new ItemTile()("glass"), 999);
    }

    Rectangle renderbox() {
        return new Rectangle(cast(int)position.X, cast(int)position.Y, 32, 64);
    }

    override void onUpdate(GameTimes gameTime) {
        state = Keyboard.GetState();
        mouseState = Mouse.GetState();
        if (actionTimer > 0) {
            actionTimer--;
        }

        hotbar.update();

        handleMovement();
        handleInteraction();
        handleMusic();

        inventory.update();

        world.camera.Position = this.hitbox.Center;

        if (state.IsKeyDown(Keys.R)) {
            this.position = Vector2(0, 0);
        }
    }

    override void onDraw(SpriteBatch spriteBatch) {
        spriteBatch.Draw(TEXTURES["entities/entity_player"], this.renderbox, TEXTURES["entities/entity_player"].Size, Color.White, spriteFlip);
    }

    override void drawAfter(SpriteBatch spriteBatch) {
        hotbar.draw(spriteBatch, selectedSlot);
        hotbar.postDraw(spriteBatch);
    }

    /++
        Returns the player's inventory.
    +/
    final ref Container getInventory() {
        return inventory;
    }

    /++
        Used on world load to set the player's inventory.
    +/
    final void setInventory(Container container) {
        inventory = container;
        hotbar.updateRef(container);
    }
}