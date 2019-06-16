module app;
import polyplex.utils.logging;
import game;
import std.parallelism;

void main() {
    LogLevel |= LogType.Info;
    LogLevel |= LogType.Warning;
    
    // Run the game
    DunesGame game = new DunesGame();
    scope(exit) {   
        game.save();
        taskPool.stop();
    }
    game.Run();
}