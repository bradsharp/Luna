# luna
luna offers elegant syntax which allows you to build beautiful object oriented programs with ease.

## Features
- Supports multiple object inheritance, avoiding ambiguity between parent-classes
- Supports all versions of Lua
- Supports accessors and mutators
- Offers a natural transition between private and public variables
- Supports static methods
- Definitions follow a C# like structure

## Usage
Download the source file and place it in your projects directory. `require` the module and store it in the variable `class`

```lua
local class = require'class'
```
### Definition
Classes are defined as follows

```lua
local class = require'class'

local planet = class {

}
```

### Scope
This module offers classes a private and public scope. Private variables can only be indexed from within the definition while public variables can be indexed outside of the definition.

When a function in the class is called a wrapper object is passed to the function as the first parameter. This wrapper allows you to set variables regardless of whether they are defined or not.
```lua
local ceres = planet()
print(ceres.PrivateVariable)
>> error PrivateVariable is not a valid member of planet
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

local planet = class {
    Name = "";
    Magnitude = 0;
}
```
#### Indexing
```lua
local ceres = planet()
ceres.Name = "Ceres"
ceres.Magnitude = 3.36
print(ceres.Name, ceres.Magnitude) 
>> Ceres, 3.36
```

### Accessors and Mutators
Accessors are useful when you wish to store a table, userdata or value of unknown type. The `get` function is called when the user wants to retrieve the `value` of the variable. The `set` function is called when the user attempts to set the `value` of the variable. Both are given the object as the first parameters, while set is also given the value the user wishes to set your variable to.

#### Creating
```lua
local class = require'class'

local planet = class {
    Radius = 0;
    SurfaceArea = {
        get = function (this)
            return 4 * math.pi * this.Radius * this.Radius
        end,
        set = function (this, value)
            this.Radius = math.sqrt(value) / (4 * math.pi)
        end
    }
}
```
#### Indexing
```lua
local ceres = planet()
ceres.Radius = 473000
print(ceres.SurfaceArea)
>> 2811461531180
```

### Methods
Methods are functions which can be called on your class, the parameters given are the object followed by the parameters the method was called with.
#### Creating
```lua
local class = require'class'

local planet = class {
    Mass = 0;
    GetGravitationalForce = function (this, distance)
        return (this.Mass * 6.67e-11) / (distance * distance)
    end;
}
```
#### Calling
```lua
local ceres = planet()
ceres.Mass = 9.393e20
print(ceres:GetGravitationalForce(473000))
>> 0.28003213709443
```
...or from the definition
```lua
this.Mass = 9.393e20
print(this.GetGravitationalForce(473000))
>> 0.28003213709443
```


### Constructors
The `__construct` method is called when a new object is created. It allows you to set any private variables and prepare the class for use. It's parameters will be the object itself followed by any variables passed into the instance function.
#### Creating
```lua
local class = require'class'

local planet = class {
    Name = "";
    Radius = 0;
    __construct = function (this, name, radius)
        this.Name = name
        this.Radius = radius
    end
}
```
#### Instancing
```lua
local ceres = planet("Ceres", 473000)
print(ceres.Name, ceres.Radius)
>> Ceres, 473000
```
### Metamethods
This module supports metamethods which can be added to your definition.

```lua
local class = require'class'

local planet = class {
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
local planet = class {
    Age = 0;
    Name = "";
    
}

local solarSystem = class {
    DistanceFromSun = 0;
}

local localPlanet = class (solarSystem, planet) {
    ShortestDistanceFromEarth = 0;
    LongestDistanceFromEarth = 0;
}
```
...or to just inherit multiple classes
```lua
local localPlanet = class (solarSystem, planet)
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

## License

MIT License

Copyright (c) 2016 Brad Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
