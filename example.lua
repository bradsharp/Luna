local class = require'class'

local list = class {

    Length = {
        get = function (this)
            return #this.List
        end
    };

    __construct = function (this, ...)
        this.List = {...}
    end;

    __index = function (this, index)
        return this.List[index]
    end;

    Add = function (this, item)
        table.insert(this.List, item)
    end;

    Remove = function (this, index)
        table.remove(this.List, index)
    end;

    Iterator = {
        get = function (this)
            return ipairs(this.List)
        end
    };

}

local newList = list("Hi", "Hello", "Howdy")

for i = 1, newList.Length do
    print(newList[i])
end
