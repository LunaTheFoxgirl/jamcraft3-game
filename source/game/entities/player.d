module game.entities.player;
import game.entity;
import polyplex;

enum PLAYER_SPEED = 5f;

class Player : Entity {
private:
    KeyboardState state;
public:
    this(World world) {
        super(world, Vector2(0f, 0f));
    }

    override Rectangle hitbox() {
        return new Rectangle(cast(int)position.X, cast(int)position.Y, 16, 32);
    }

    override void update(GameTimes gameTime) {
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
        world.camera.Position = this.position;
        world.camera.Zoom = 1.6f;
    }

    override void draw(SpriteBatch spriteBatch) {
        
    }
}