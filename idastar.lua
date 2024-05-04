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

local function pathBlankToPosition(puzzle, target)

    local paths = {}
-- Enumerate all possible paths 10 spaces from the blank to find the one we want. Heuristic is manhattan distance.
    local function searchBruceForce(path, closedPaths, target, bound, g)
        local newMoves = {}

        if path:getPosition(0).x > 1 then 
            local validMove, newMove = path:simulateMove(LEFT)
            if validMove == true and closedPaths[newMove:serialize()] == nil then
                local h = newMove:blankManhattan(target.x, target.y)
                -- print(" \"" .. path:serialize() .. "\" -> \"" .. newMove:serialize() .. "\": h:" .. h .. " g:" .. g)
                table.insert(newMoves, { puzzle = newMove, h = h, parent = paths[path:serialize()], position = newMove:getPosition(0), g = g, direction = "LEFT"})
            end
        end
        if path:getPosition(0).x < path:getBoardSize() then
            local validMove, newMove = path:simulateMove(RIGHT)
            if validMove == true and closedPaths[newMove:serialize()] == nil then
                local h = newMove:blankManhattan(target.x, target.y)
                -- print(" \"" .. path:serialize() .. "\" -> \"" .. newMove:serialize() .. "\": h:" .. h .. " g:" .. g)
                table.insert(newMoves, { puzzle = newMove, h = h, parent = paths[path:serialize()], position = newMove:getPosition(0), g = g, direction = "RIGHT"})
            end
        end
        if path:getPosition(0).y > 1 then 
            local validMove, newMove = path:simulateMove(UP)
            if validMove == true and closedPaths[newMove:serialize()] == nil then
                local h = newMove:blankManhattan(target.x, target.y)
                -- print(" \"" .. path:serialize() .. "\" -> \"" .. newMove:serialize() .. "\": h:" .. h .. " g:" .. g)
                table.insert(newMoves, { puzzle = newMove, h = h, parent = paths[path:serialize()], position = newMove:getPosition(0), g = g, direction = "UP"})
            end
        end
        if path:getPosition(0).y < path:getBoardSize() then
            local validMove, newMove = path:simulateMove(DOWN)
            if validMove == true and closedPaths[newMove:serialize()] == nil then
                local h = newMove:blankManhattan(target.x, target.y)
                -- print(" \"" .. path:serialize() .. "\" -> \"" .. newMove:serialize() .. "\": h:" .. h .. " g:" .. g)
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

    local target = target

    local closedPaths = {}
    closedPaths[puzzle:serialize()] = "OCCUPIED"
    if puzzle:getHeuristic() > 0 then
        searchBruceForce(puzzle:clone(), closedPaths, target, 10, 0)
    end

    table.sort(paths, function(a, b)
        if a.h ~= b.h then
            return a.h < b.h
        end

        return a.g < b.g
    end)

    -- Print directions in reverse order
    local cur = paths[1]
    local directions = {}

    -- Use the parent to get the whole path
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
    return directions, paths[1].puzzle
end

-- Runs an algorithm with the blank tile to move a tile right or left. \
-- This assumes the blank tile is already placed adjacent to another tile in the proper position.
-- direction is the direction we want to move the adjacent tile
-- tilesToMove is the number of spaces we want to move our target
local function moveXAlgorithm(puzzle, direction, tilesToMove)
    print("======================")
    puzzle:prettyPrint()
    if direction == LEFT then
        if tilesToMove > 1 then
            for i = 1, tilesToMove - 1 do
                print("--------------")
                puzzle:move(RIGHT)
                print("--------------")
                puzzle:prettyPrint()
                puzzle:move(DOWN)
                print("--------------")
                puzzle:prettyPrint()
                puzzle:move(LEFT)
                print("--------------")
                puzzle:prettyPrint()
                puzzle:move(LEFT)
                print("--------------")
                puzzle:prettyPrint()
                puzzle:move(UP)
                print("--------------")
                puzzle:prettyPrint()
            end
        else 
            
        end
        puzzle:move(RIGHT)
        puzzle:prettyPrint()
        print("tttttttttttttttttt")
    end
end

local function moveYAlgorithm(puzzle, direction, tilesToMove)
    print(tilesToMove)
    print("======================~~~~")
    puzzle:prettyPrint()
    if direction == UP then
        if tilesToMove > 1 then
            print(tilesToMove)
            for i = 1, tilesToMove - 1 do
                print("asdf: ", i)
                print("--------------")
                puzzle:prettyPrint()
                puzzle:move(DOWN)
                print("--------------")
                puzzle:prettyPrint()
                puzzle:move(RIGHT)
                print("--------------")
                puzzle:prettyPrint()
                puzzle:move(UP)
                print("--------------")
                puzzle:prettyPrint()
                puzzle:move(UP)
                print("--------------")
                puzzle:prettyPrint()
                puzzle:move(LEFT)
                print("--------------")
                puzzle:prettyPrint()
            end
        end
        puzzle:move(DOWN)
        puzzle:prettyPrint()
        print("tttttttttttttttttt")
        puzzle:prettyPrint()
    end
end

local function solve(puzzle, onePosition, desiredPosition, tileValue)
    if onePosition.x ~= desiredPosition.x or onePosition.y ~= desiredPosition.y then
        if isRightOf(onePosition, desiredPosition) then
            puzzle:lockPosition(onePosition.x, onePosition.y)
            local dir, puzz = pathBlankToPosition(puzzle, {x = onePosition.x - 1, y = onePosition.y})
            puzz:unlockLatest()
            puzzle = puzz
        else
            puzzle:lockPosition(onePosition.x, onePosition.y)
            local dir, puzz = pathBlankToPosition(puzzle, {x = onePosition.x + 1, y = onePosition.y})
            puzz:unlockLatest()
            puzzle = puzz    
        end
    
        local onePosition = puzzle:getPosition(tileValue);
        local desiredOnePosition = puzzle:getGoals(tileValue)[tileValue]
    
        local tilesToMove = math.abs(onePosition.x - desiredOnePosition.x)
    
        moveXAlgorithm(puzzle, LEFT, tilesToMove)
    
        puzzle:prettyPrint()
    
        local onePosition = puzzle:getPosition(tileValue);
        local desiredPosition = puzzle:getGoals(tileValue)[tileValue]
    
        if isAbove(onePosition, desiredPosition) then
            puzzle:lockPosition(onePosition.x, onePosition.y)
            local dir, puzz = pathBlankToPosition(puzzle, {x = onePosition.x, y = onePosition.y + 1})
            puzz:unlockLatest()
            puzzle = puzz
        else
            puzzle:lockPosition(onePosition.x, onePosition.y)
            local dir, puzz = pathBlankToPosition(puzzle, {x = onePosition.x, y = onePosition.y - 1})
            puzz:unlockLatest()
            puzzle = puzz    
        end
    
        local onePosition = puzzle:getPosition(tileValue);
        local desiredOnePosition = puzzle:getGoals(tileValue)[tileValue]
    
        local tilesToMove = math.abs(onePosition.y - desiredOnePosition.y)
    
        moveYAlgorithm(puzzle, UP, tilesToMove)
    
        puzzle:prettyPrint()
    end
    puzzle:lockPosition(desiredPosition.x, desiredPosition.y)
    return puzzle
end

local state = {
    {   6,   4,   3,  15,  17 },
    {   9,  23,   5,   2,  14 },
    {   11,   0,  1,   7,  13 },
    {  10,  12,   8,  19,  20 },
    {  22,  21,  16,  18,  24 },
}

local puzzle = Puzzle:new(5, state)
puzzle:generateWinningString()

print("Starting position")
puzzle:prettyPrint()

local puzzle = solve(puzzle, puzzle:getPosition(1), puzzle:getGoals()[1], 1)
puzzle = solve(puzzle, puzzle:getPosition(2), puzzle:getGoals()[2], 2)
puzzle = solve(puzzle, puzzle:getPosition(3), puzzle:getGoals()[3], 3)
-- Switch to a modified goals state so that we place the 4 and 5 in a specific way to solve them (for a 5x5 puzzle, but this example applies for all sizes). The location of those two tiles is all that matters
local newGoals = puzzle:getGoals()
-- This is modifying the goals table so that our algorithm 
newGoals[puzzle:getBoardSize() - 1] = {y = 1, x = 5}
newGoals[puzzle:getBoardSize()] = {y = 2, x = 5}

puzzle = solve(puzzle, puzzle:getPosition(4), puzzle:getGoals()[4], 4)