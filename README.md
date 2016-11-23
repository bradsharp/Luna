# luamond
An advanced module that allows you to create classes with a C# like structure which support multiple inheritance.

The library is currently in its early stages so expect bugs and or performance issues.

## Features
- Supports multiple object inheritance
- Definitions follow a C# like structure
- Supports accessors and mutators
- Offers a natural transition between private and public variables
- Supports static methods
- Supports all versions of Lua

## Usage
Download the source file and place it in your projects directory. `require` the module and store it in the variable `class`

```lua
local class = require'classes'
```
### Definition
Classes are defined as follows

```lua
local class = require'class'

local className = class {

}
```

### Scope
This module offers classes a private and public scope. Private variables can only be indexed from within the definition while public variables can be indexed outside of the definition.

When a function in the class is called a wrapper object is passed to the function as the first parameter. This wrapper allows you to set variables regardless of whether they are defined or not.
```lua
local fanta = drink()
print(fanta.PrivateVariable)
>> Error PrivateVariable is not a valid member of drink
```
...but from the definition itself
```lua
print(this.PrivateVariable)
>> nil
```

It also means that if you reference it outside the definition you will pass the wrapper object and not the object itself. In order to return the object just call the wrapper


```lua
local wrapper = this
local object = wrapper()
```


### Properties
Properties are required to remain whatever type they are defined as, tables, userdatas and variable types should be defined using accessors.
#### Creating
```lua
local class = require'class'

local drink = class {
    Name = "";
    Price = 0;
}
```
#### Indexing
```lua
local fanta = drink()
fanta.Name = "Fanta"
fanta.Price = 100
print(fanta.Name, fanta.Price) 
>> Fanta, 100
```

### Accessors and Mutators
Accessors are useful when you wish to store a table, userdata or value of unknown type. The `get` function is called when the user wants to retrieve the `value` of the variable. The `set` function is called when the user attempts to set the `value` of the variable. Both are given the object as the first parameters, while set is also given the value the user wishes to set your variable to.

#### Creating
```lua
local class = require'class'

local drink = class {
    Ingredients = {
        get = function (this)
            return this._Ingredients or {}
        end,
        set = function (this, value)
            this._Ingredients = value
        end
    }
}
```
#### Indexing
```lua
local fanta = drink()
fanta.Ingredients = {"Orange", "Sugar", "Other"}
print(table.concat(fanta.Ingredients))
>> Orange, Sugar, Other
```

### Methods
Methods are functions which can be called on your class, the parameters given are the object followed by the parameters the method was called with.
#### Creating
```lua
local class = require'class'

local drink = class {
    Volume = 100;

    Drink = function (this)
        this.Volume = 0
    end;
}
```
#### Calling
```lua
local fanta = drink()
fanta:Drink()
```
...or from the definition
```lua
this.Drink()
```


### Constructors
The `__construct` method is called when a new object is created. It allows you to set any private variables and prepare the class for use. It's parameters will be the object itself followed by any variables passed into the instance function.
#### Creating
```lua
local class = require'class'

local drink = class {
    __construct = function (this, ...)
        print(...)
    end
}
```
#### Instancing
```lua
local fanta = drink("Orange", "Sugar")
>> Orange, Sugar
```
### Metamethods
This module supports metamethods which can be added to your definition.

```lua
local class = require'class'

local drink = class {
    Name = "";
    __tostring = function (this)
        return this.Name
    end;
}
```
The `__index` metamethod will override any errors that may have occured if it did not exist, it is up to the user defining the class to impliment their own.

The `__newindex` metamethod is called as soon as the user attempts to set a value. If an error occurs then the internal code will not continue executing and the value or accessor will not be set.
 
Both these methods are ignored when indexing private variables.

### Inheritance
This module supports multiple inheritance which means a class can inherit many other classes.

```lua
local drink = class {
    Name = "";
}

local purchaseable = class {
    Price = 0;
    Purchase = function (this, user)
        if user.Money >= this.Price then
            user.Money = user.Money - this.Price
            user:Give(this())
        end
    end
}

local fizzyDrink = class (drink, purchaseable) {
    Name = "Soda";
    Price = 100;
}
```
In the case of two inherited classes having a different value for a property, the class that is first in the list of inherited classes will be considered more important and therefore have its value used. This is also the case for metamethods.

### Static
Static functions and variables exist within the definition itself rather than per object. They can be added to the definition in the same way that any other method or property is but they can not make use of the wrapper as mentioned in the scope section. They are currently partially supported.

```lua
local class = require'class'

local website = class {
    Domain = "http://www.";
}

print(website.Domain)
>> http://www.
```

### Reflection
Reflection is not currently supported

