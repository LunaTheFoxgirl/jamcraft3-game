module game.utils;
import polyplex.math;
import game.chunk;
import game.tile;
import config;

T wrapTilePos(T)(T vec) if (IsVector!T) {
    T vecT = vec;
    return T(
        (vec.X < 0 ? CHUNK_SIZE-(vec.X*-1)%CHUNK_SIZE : vec.X)%CHUNK_SIZE, 
        (vec.Y < 0 ? CHUNK_SIZE-(vec.Y*-1)%CHUNK_SIZE : vec.Y)%CHUNK_SIZE);
}

Vector2 vec2f(T)(T vec) if (IsVector!T) {
    return Vector2(cast(float)vec.X, cast(float)vec.Y);
}

/++
    Converts from tile position to pixels
+/
Vector2i toPixels(T)(T vec) if (IsVector!T) {
    float c = cast(float)TILE_SIZE;
    int bx = cast(int)Mathf.Floor(cast(float)vec.X*c);
    int by = cast(int)Mathf.Floor(cast(float)vec.Y*c);
    return Vector2i(bx, by);
}

/++
    Converts from pixels to tile position
+/
Vector2i toTilePos(T)(T vec) if (IsVector!T) {
    float c = cast(float)TILE_SIZE;
    int bx = cast(int)Mathf.Floor(cast(float)vec.X/c);
    int by = cast(int)Mathf.Floor(cast(float)vec.Y/c);
    return Vector2i(bx, by);
}

/++
    Converts pixel to chunk position
+/
T toChunkPos(T)(T vec) if (IsVector!T) {
    return vec.toTilePos.tilePosToChunkPos;
}

/++
    Converts from chunk position to tile position
+/
Vector2i chunkPosToTilePos(T)(T vec) if (IsVector!T) {
    float c = cast(float)TILE_SIZE;
    int bx = cast(int)Mathf.Floor(cast(float)vec.X*c);
    int by = cast(int)Mathf.Floor(cast(float)vec.Y*c);
    return Vector2i(bx, by);
}

/++
    Converts from tile position to chunk position
+/
Vector2i tilePosToChunkPos(T)(T vec) if (IsVector!T) {
    float c = cast(float)CHUNK_SIZE;
    int bx = cast(int)Mathf.Floor(cast(float)vec.X/c);
    int by = cast(int)Mathf.Floor(cast(float)vec.Y/c);
    return Vector2i(bx, by);
}

/++
    Calculate adjacent positions
+/
T[] getAdjacent(T)(T pos, int sx, int sy) if (IsVector!T) {
    T[] adjacent;
    foreach(x; 0..sx) {
        foreach(y; 0..sy) {
            adjacent ~= T(pos.X+(x-(sx/2)), pos.Y+(y-(sy/2)));
        }
    }
    return adjacent;
}

/++
    Calculate adjacent positions, without center.
+/
T[] getAdjacentEx(T)(T pos, int sx, int sy) if (IsVector!T) {
    T[] adjacent;
    foreach(x; 0..sx*2) {
        foreach(y; 0..sy*2) {
            if (x == sx/2 && y == sy/2) continue;
            adjacent ~= T(pos.X+(x-(sx/2)), pos.Y+(y-(sy/2)));
        }
    }
    return adjacent;
}

bool withinChunkBounds(Vector2i pos) {
    return (pos.X >= 0 && pos.X <= CHUNK_SIZE &&
            pos.Y >= 0 && pos.Y <= CHUNK_SIZE);
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
    Calculate AABB collissions on the Y axis.
+/
float calculateAABBCollissionY(Rectangle a, Rectangle b) {
    if (a.Intersects(b) || b.Intersects(a)) {
        if (a.Center.Y < b.Center.Y) {
            return cast(float)(b.Top-a.Bottom)/4f;
        }
        return cast(float)(b.Bottom-a.Top);
    }
    return 0.0f;
}