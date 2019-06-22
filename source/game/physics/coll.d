module game.physics.coll;
import game.world;
import game.utils;
import game.tile;
import game.entity;
import polyplex;

/++
    Gets wether a rectangle collides with the world.

    Returns a Vector with values set to 0, 0 if no collission occured.
+/
Vector2 collidesRect(World world, Entity e, Rectangle area, Vector2 velocity, int adjacency = 4) {
    float vx = 0;
    float vy = 0;
    Vector2i centerTile = Vector2i(cast(int)area.Center.X, cast(int)area.Center.Y).toTilePos;
    foreach(adjacent; centerTile.getAdjacent(adjacency, adjacency)) {
        Tile b = world.tileAt(adjacent);
        if (b !is null && b.isCollidable()) {
            if (!b.isCollidableWith(e, velocity)) continue;
            Rectangle bAABB = b.hitbox;
            float x = calculateAABBCollissionX(area, bAABB);
            float y = calculateAABBCollissionY(area, bAABB);
            if (x != 0) vx = x;
            if (y != 0) vy = y;
        }
    }
    return Vector2(vx, vy);
}

/++
    Gets wether a Vector2 collides with the world.

    Returns a Vector with values set to 0, 0 if no collission occured.
+/
Vector2 collidesVec2(T)(World world, Entity e, T vec, T velocity, int adjacency = 2) if (IsVector!T) {
    float vx = 0;
    float vy = 0;
    Vector2i centerTile = Vector2i(cast(int)vec.X, cast(int)vec.Y).toTilePos;
    foreach(adjacent; centerTile.getAdjacent(adjacency, adjacency)) {
        Tile b = world.tileAt(adjacent);
        if (b !is null && b.isCollidable()) {
            if (!b.isCollidableWith(e, velocity)) continue;
            Rectangle bAABB = b.hitbox;
            float x = calculateAABBCollissionX(vec, bAABB);
            float y = calculateAABBCollissionY(vec, bAABB);
            if (x != 0) vx = x;
            if (y != 0) vy = y;
        }
    }
    return Vector2(vx, vy);
}

/++
    Calcuate AABB collissions on the X axis.
+/
float calculateAABBCollissionX(Rectangle a, Rectangle b) {
    if (a.Intersects(b) || b.Intersects(a)) {
        if (a.Center.X < b.Center.X) {
            return cast(float)(b.Left-a.Right);
        }
        return cast(float)(b.Right-a.Left);
    }
    return 0.0f;
}

/++
    Calcuate AABB collissions on the X axis.
+/
float calculateAABBCollissionX(T)(T a, Rectangle b) if (IsVector!T) {
    if (b.Intersects(a)) {
        if (a.X >= b.Center.X) {
            return cast(float)(b.Right-a.X);
        }
        return cast(float)(b.Left-a.X);
    }
    return 0.0f;
}


/++
    Calculate AABB collissions on the Y axis.
+/
float calculateAABBCollissionY(Rectangle a, Rectangle b) {
    if (a.Intersects(b) || b.Intersects(a)) {
        if (a.Center.Y < b.Center.Y) {
            return cast(float)(b.Top-a.Bottom);
        }
        return cast(float)(b.Bottom-a.Top);
    }
    return 0.0f;
}

/++
    Calcuate AABB collissions on the Y axis.
+/
float calculateAABBCollissionY(T)(T a, Rectangle b) if(IsVector!T) {
    if (b.Intersects(a)) {
        if (a.Y < b.Center.Y) {
            return cast(float)(b.Top-a.Y);
        }
        return cast(float)(b.Bottom-a.Y);
    }
    return 0.0f;
}
