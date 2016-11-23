# Lua Classes
A custom class library for use with Lua

## Usage

```lua
local purchaseable = class {

    Price = 0;

    Purchase = function (this, user)
        -- Prompt user to purchase the item
    end

}

local weapon = class {
    Damage = 0;
    Name = "";
}

local sword = class (weapon, purchaseable) {
    Name = "Sword";
    Damage = 100;
}
```
