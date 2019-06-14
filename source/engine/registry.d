module engine.registry;

class Registry(T) {
private:
    TypeInfo_Class[string] registeredTypes;

public:
    void register(U)(string name) if (is(U : T)) {
        registeredTypes[name] = typeid(U);
    }

    T createNew(string name) {
        return cast(T)registeredTypes[name].create();
    }
}