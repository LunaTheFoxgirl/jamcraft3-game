module game.utils;
import polyplex.math;
import game.chunk;
import game.tile;

T wrapTilePos(T)(T vec) if (IsVector!T) {
    T vecT = vec;
    return T(
        (vec.X < 0 ? CHUNK_SIZE-(vec.X*-1)%CHUNK_SIZE : vec.X)%CHUNK_SIZE, 
        (vec.Y < 0 ? CHUNK_SIZE-(vec.Y*-1)%CHUNK_SIZE : vec.Y)%CHUNK_SIZE);
}

Vector2 vec2f(T)(T vec) if (IsVector!T) {
    return Vector2(cast(float)vec.X, cast(float)vec.Y);
}

Vector2i toTilePos(T)(T vec) if (IsVector!T) {
    float c = cast(float)BLOCK_SIZE;
    int bx = cast(int)Mathf.Floor(cast(float)vec.X/c);
    int by = cast(int)Mathf.Floor(cast(float)vec.Y/c);
    return Vector2i(bx, by);
}

Vector2i tilePosToChunkPos(T)(T vec) if (IsVector!T) {
    float c = cast(float)CHUNK_SIZE;
    int bx = cast(int)Mathf.Floor(cast(float)vec.X/c);
    int by = cast(int)Mathf.Floor(cast(float)vec.Y/c);
    return Vector2i(bx, by);
}

T toChunkPos(T)(T vec) if (IsVector!T) {
    return vec.toTilePos.tilePosToChunkPos;
}

T[] getAdjacent(T)(T pos, int sx, int sy) if (IsVector!T) {
    T[] adjacent;
    foreach(x; 0..sx) {
        foreach(y; 0..sy) {
            adjacent ~= T(pos.X+(x-(sx/2)), pos.Y+(y-(sy/2)));
        }
    }
    return adjacent;
}