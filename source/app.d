module app;
import polyplex.utils.logging;
import game;

void main() {
    LogLevel |= LogType.Info;
    
    // Run the game
    DunesGame game = new DunesGame();
    game.Run();
}