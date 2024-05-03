-- local profile = require("profile")

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
        path[#path + 1] = simPuzzle
        dirs[#dirs + 1] = dir
    
        local t = search(path, g + 1, bound, dirs)
        if t == true then
            return true
        end
        if t < min then
            min = t
        end
    
        path[serializedPuzzle] = nil
        path[#path] = nil
        dirs[#dirs] = nil
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


-- profile.start()
-- local before = os.clock()
-- local directions = idaStar(puzzle)
-- local after = os.clock()
-- -- profile.stop()
-- print(string.format("Loop took %0.6f seconds to run: " .. startingState, after - before ))

local paths = {}
-- Enumerate all possible paths from the blank to find the one we want
local function searchBruceForce(path, closedPaths, target, bound, g)
    local newMoves = {}

    if path:getPosition(0).x > 1 then 
        local validMove, newMove = path:simulateMove(LEFT)
        if validMove == true and closedPaths[newMove:serialize()] == nil then
            local h = newMove:blankManhattan(target.x, target.y)
            print(h .. " " .. g .. " \"" .. path:serialize() .. "\" -> \"" .. newMove:serialize() .. "\"")
            table.insert(newMoves, { puzzle = newMove, h = h, parent = paths[path:serialize()], position = newMove:getPosition(0), g = g, direction = "LEFT"})
        end
    end
    if path:getPosition(0).x < path:getBoardSize() then
        local validMove, newMove = path:simulateMove(RIGHT)
        if validMove == true and closedPaths[newMove:serialize()] == nil then
            local h = newMove:blankManhattan(target.x, target.y)
            print(h .. " " .. g .. " \"" .. path:serialize() .. "\" -> \"" .. newMove:serialize() .. "\"")
            table.insert(newMoves, { puzzle = newMove, h = h, parent = paths[path:serialize()], position = newMove:getPosition(0), g = g, direction = "RIGHT"})
        end
    end
    if path:getPosition(0).y > 1 then 
        local validMove, newMove = path:simulateMove(UP)
        if validMove == true and closedPaths[newMove:serialize()] == nil then
            local h = newMove:blankManhattan(target.x, target.y)
            print(h .. " " .. g .. " \"" .. path:serialize() .. "\" -> \"" .. newMove:serialize() .. "\"")
            table.insert(newMoves, { puzzle = newMove, h = h, parent = paths[path:serialize()], position = newMove:getPosition(0), g = g, direction = "UP"})
        end
    end
    if path:getPosition(0).y < path:getBoardSize() then
        local validMove, newMove = path:simulateMove(DOWN)
        if validMove == true and closedPaths[newMove:serialize()] == nil then
            local h = newMove:blankManhattan(target.x, target.y)
            print(h .. " " .. g .. " \"" .. path:serialize() .. "\" -> \"" .. newMove:serialize() .. "\"")
            table.insert(newMoves, { puzzle = newMove, h = h, parent = paths[path:serialize()], position = newMove:getPosition(0), g = g, direction = "DOWN"})
        end
    end

    table.sort(newMoves, function (a, b) 
        return a.h < b.h
    end)
    if #newMoves == 0 or g > bound then
        return
    end
    for i = 1, #newMoves do
        closedPaths[newMoves[i].puzzle:serialize()] = "OCCUPIED"
        paths[#paths + 1] = newMoves[i]
        paths[newMoves[i].puzzle:serialize()] = newMoves[i]
        if newMoves[i].h > 0 then
            searchBruceForce(newMoves[i].puzzle, closedPaths, target, bound, g + 1)
        end
    end
end
local target = {x = 2, y = 1}
local stateB = {
    {4, 14, 15, 2, 22},
    {0, 23, 5, 11, 7},
    {20, 3, 12, 6, 17},
    {18, 19, 24, 8, 16},
    {13, 10, 1, 9, 21}
}

local puzzle = Puzzle:new(5, stateB)
puzzle:generateWinningString()
puzzle:lockPosition(1, 1)
puzzle:lockPosition(2, 2)
local startingState = (puzzle:serialize())
-- puzzle:lockPosition(1,1)
-- puzzle:lockPosition(2,2)
local closedPaths = {}
closedPaths[puzzle:serialize()] = "OCCUPIED"
searchBruceForce(puzzle:clone(), closedPaths, target, 8, 0)

table.sort(paths, function(a, b)
    if a.h == b.h then
        return a.g < b.g
    end
    return a.h < b.h  -- Primary sort by 'h'
end)

for i = 1, #paths do
    print("g: " .. paths[i].g .. " h: " .. paths[i].h .. " " .. paths[i].puzzle:serialize())
end

local cur = paths[1]
local directions = {}
while cur.parent ~= nil do
    table.insert(directions, cur.direction)
    cur = cur.parent
end
if cur.direction then
    table.insert(directions, cur.direction)
end

for i = #directions, 1, -1 do
    print(directions[i])
end