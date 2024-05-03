local Puzzle = require("Puzzle")

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function h(puzzle)
    return puzzle:getHeuristic()
end

local function isPuzzleInPath(puzzle, path)
    return path[puzzle:serialize()] ~= nil
end

function Puzzle:simulateMove(dir)
    local simPuzzle = deepcopy(self)
    local moveSuccessful = simPuzzle:move(dir)
    return moveSuccessful, simPuzzle
end

local function search(path, g, bound, dirs)
    local cur = path[#path]
    local h = h(cur)
    local f = g + h

    if f > bound then
        return f
    end

    if cur:checkWin() then
        return true
    end
    local min = INF

    for i, dir in ipairs(DIRECTIONS) do
        if #dirs > 0 and -dir[1] == dirs[#dirs][1] and -dirs[#dirs][2] == -dir[2] then
            goto continue
        end
        local validMove, simPuzzle = cur:simulateMove(dir)        
    
        if not validMove or isPuzzleInPath(simPuzzle, path) then
            goto continue
        end
    
        local serializedPuzzle = simPuzzle:serialize()
        path[serializedPuzzle] = "OCCUPIED"
        table.insert(path, simPuzzle)
        table.insert(dirs, dir)
    
        local t = search(path, g + 1, bound, dirs)
        if t == true then
            return true
        end
        if t < min then
            min = t
        end
    
        path[serializedPuzzle] = nil
        table.remove(path)
        table.remove(dirs)
    
        ::continue::
    end
    return min
end

local function idaStar(puzzle)
    if puzzle:checkWin() then
        return {}
    end

    local bound = h(puzzle)
    local path = {puzzle}
    local dirs = {}
    while true do
        local rem = search(path, 0, bound, dirs)
        if rem == true then
            return dirs
        elseif rem == INF then
            return nil
        end
        bound = rem
    end
end

local puzzle = Puzzle:new(3)
puzzle:generateWinningString()
puzzle:shuffle()
local startingState = (puzzle:serialize())
local before = os.clock()
local directions = idaStar(puzzle)
local after = os.clock()
print(string.format("Loop took %0.6f seconds to run: " .. startingState, after - before ))
-- print(#directions)
-- for index, dir in pairs(directions) do
--   print(dir[3])
-- end