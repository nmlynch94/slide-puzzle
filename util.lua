-- pretty print 
function prettyPrint(t, indent, done)
    done = done or {}
    indent = indent or 0
    local keys = {}

    local function basicSerialize(o)
        if type(o) == "number" then
            return tostring(o)
        elseif type(o) == "boolean" then
            return tostring(o)
        else -- assume it is a string
            return string.format("%q", o)
        end
    end

    for k, v in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then
            return a < b
        else
            return type(a) < type(b)
        end
    end)

    for i, k in ipairs(keys) do
        local v = t[k]
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            if done[v] then
                print(formatting .. tostring(v) .. " [circular reference]")
            else
                done[v] = true
                print(formatting)
                prettyPrint(v, indent + 1, done)
                done[v] = nil -- Allow reuse in other tables
            end
        else
            print(formatting .. basicSerialize(v))
        end
    end
end


-- All of these take two objects like {x = 1, y = 2} and are used
-- to determine their position relative to each other
function isRightOf(item1, item2)
    return item1.x > item2.x
end

function isLeftOf(item1, item2)
    return item1.x < item2.x
end

function isBelow(item1, item2)
    return item1.y > item2.y
end

function isAbove(item1, item2)
    return item1.y < item2.y
end

function map(tbl, f)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = f(v)
    end
    return t
end

function printDirectionsTenPerLine(directions)
    if not directions or #directions == 0 then
        print("No directions to display.")
        return
    end

    local entriesPerLine = 10
    local count = 0
    local line = ""

    for i, dir in ipairs(directions) do
        line = line .. dir.direction
        count = count + 1
        -- Check if we should add a comma
        if i < #directions then
            line = line .. ", "
        end
        -- Check if we've reached 10 entries or the end of the list
        if count == entriesPerLine or i == #directions then
            print(line)
            line = ""
            count = 0
        end
    end
end

function split (inputstr, sep)
    if sep == nil then
       sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
       table.insert(t, str)
    end
    return t
 end