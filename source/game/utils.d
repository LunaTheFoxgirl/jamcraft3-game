module game.utils;
import polyplex.math;
import game.chunk;
import game.block;

T wrapBlockPos(T)(T vec) if (IsVector!T) {
    T vecT = vec;
    return T(
        (vec.X < 0 ? CHUNK_SIZE-(vec.X*-1)%CHUNK_SIZE : vec.X)%CHUNK_SIZE, 
        (vec.Y < 0 ? CHUNK_SIZE-(vec.Y*-1)%CHUNK_SIZE : vec.Y)%CHUNK_SIZE);
}

Vector2 vec2f(T)(T vec) if (IsVector!T) {
    return Vector2(cast(int)vec.X, cast(int)vec.Y);
}

T toBlockPos(T)(T vec) if (IsVector!T) {
    return T(vec.X/BLOCK_SIZE, vec.Y/BLOCK_SIZE);
}

T blockPosToChunkPos(T)(T vec) if (IsVector!T) {
    T calc = T((vec.X < 0 ? vec.X+1 : vec.X)/CHUNK_SIZE, (vec.Y < 0 ? vec.Y+1 : vec.Y)/CHUNK_SIZE);
    return T((vec.X < 0 ? calc.X-1 : calc.X), (vec.Y < 0 ? calc.Y-1 : calc.Y));
}

T toChunkPos(T)(T vec) if (IsVector!T) {
    return vec.toBlockPos.blockPosToChunkPos;
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