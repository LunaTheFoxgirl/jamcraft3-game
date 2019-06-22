module game.input;
import polyplex;

__gshared InputSystem Input;

/++
    Input system is a system for managing input
+/
class InputSystem {
private:
    KeyboardState currentKeyboard;
    KeyboardState lastKeyboard;

    MouseState currentMouse;
    MouseState lastMouse;

    bool mouseInterrupted = false;

public:

    /++
        Initialize input system
    +/
    this() {
        currentKeyboard = Keyboard.GetState();
        currentMouse = Mouse.GetState();

        lastKeyboard = currentKeyboard;
        lastMouse = currentMouse;
    }

    /++
        Returns true if specified key is held down
    +/
    bool IsKeyDown(Keys key) {
        return currentKeyboard.IsKeyDown(key);
    }

    /++
        Returns true if specified key was pressed once
    +/
    bool IsKeyPressed(Keys key) {
        return IsKeyDown(key) && lastKeyboard.IsKeyUp(key);
    }

    /++
        Returns true if specified key was released last frame
    +/
    bool IsKeyReleased(Keys key) {
        return IsKeyUp(key) && lastKeyboard.IsKeyDown(key);
    }

    /++
        Returns true if specified key is held down
    +/
    bool IsKeyUp(Keys key) {
        return currentKeyboard.IsKeyUp(key);
    }

    /++
        Returns true if specified mouse button is held down
    +/
    bool IsButtonDown(MouseButton button) {
        if (mouseInterrupted) return false;
        return currentMouse.IsButtonPressed(button);
    }

    /++
        Returns true if specified mouse button was pressed once
    +/
    bool IsButtonPressed(MouseButton button) {
        if (mouseInterrupted) return false;
        return IsButtonDown(button) && lastMouse.IsButtonReleased(button);
    }

    /++
        Returns true if specified mouse button was released last frame
    +/
    bool IsButtonReleased(MouseButton button) {
        if (mouseInterrupted) return false;
        return IsButtonUp(button) && lastMouse.IsButtonReleased(button);
    }

    /++
        Returns true if specified mouse button is held down
    +/
    bool IsButtonUp(MouseButton button) {
        if (mouseInterrupted) return false;
        return currentMouse.IsButtonReleased(key);
    }

    /++
        Returns the scroll
    +/
    float GetScroll() {
        return currentMouse.Position.Z;
    }

    /++
        Returns the mouse position
    +/
    Vector2 Position() {
        return Vector2(currentMouse.Position.X, currentMouse.Position.Y);
    }


    /++
        Forces mouse clicks to be 
    +/
    void interruptMouse() {
        mouseInterrupted = true;
    }

    void beginInput() {
        currentKeyboard = Keyboard.GetState();
        currentMouse = Mouse.GetState();
    }

    void endInput() {
        lastKeyboard = currentKeyboard;
        lastMouse = currentMouse;
        mouseInterrupted = false;
    }
}