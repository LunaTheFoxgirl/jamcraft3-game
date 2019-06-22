module game.physics.phys;
import polyplex.math;

/++
    An object that physically interacts with the world via collission.
+/
class PhysicsObject {
private:
    Vector2 size;
    Vector2 offset;

protected:
    final void updateHitbox() {
        this.hitbox.X       =  cast(int)(position.X+offset.X);
        this.hitbox.Y       =  cast(int)(position.Y+offset.Y);
        this.hitbox.Width   =               cast(int)(size.X);
        this.hitbox.Height  =               cast(int)(size.Y);
    }

public:
    /++
        The position of the object
    +/
    Vector2 position;
    
    /++
        The momentum to be applied to the object
    +/
    Vector2 momentum;

    /++
        The object's hitbox
    +/
    Rectangle hitbox;

    this(Vector2 start, Vector2 size) {
        this.position = Vector2(0, 0);
        this.momentum = Vector2(0, 0);
        this.hitbox = new Rectangle(0, 0, 0, 0);
        setSize(start, size);
    }

    /++
        Update the size of the hitbox

        Start defines top left corner, size defines how big from that point the hitbox is.
    +/
    final void setSize(Vector2 start, Vector2 size) {
        this.offset = start;
        this.size = size;
    }

    /++
        Returns the feet (bottom-middle) of the hitbox
    +/
    final Vector2 feet() {
        return Vector2(center.X, hitbox.Bottom);
    }

    /++
        Returns the center of the hitbox
    +/
    final Vector2 center() {
        return hitbox.Center();
    }
    
    /++
        Returns the head (top-middle) of the hitbox
    +/
    final Vector2 head() {
        return Vector2(center.X, hitbox.Y);
    }

    /++
        Limit momentum to a speed limit (in both negative and positive values)
    +/
    final void limitMomentum(float speedLimit) {

        // X axis
        if (this.momentum.X > speedLimit) this.momentum.X = speedLimit;
        if (this.momentum.X < -speedLimit) this.momentum.X = -speedLimit;

        // Y axis
        if (this.momentum.Y > speedLimit) this.momentum.Y = speedLimit;
        if (this.momentum.Y < -speedLimit) this.momentum.Y = -speedLimit;
    }
}