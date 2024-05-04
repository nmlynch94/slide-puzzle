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

function pathBlankToPosition(puzzle, target)
    local originalPuzzle = puzzle:clone()

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
        local dir = directions[i]
        if dir == "LEFT" then
            originalPuzzle:move(LEFT)
        elseif dir == "RIGHT" then
            originalPuzzle:move(RIGHT)
        elseif dir == "UP" then
            originalPuzzle:move(UP)
        elseif dir == "DOWN" then
            originalPuzzle:move(DOWN)
        end
    end
    return directions, originalPuzzle
end

-- Runs an algorithm with the blank tile to move a tile right or left. \
-- This assumes the blank tile is already placed adjacent to another tile in the proper position.
-- direction is the direction we want to move the adjacent tile
-- tilesToMove is the number of spaces we want to move our target
function moveAlgorithm(puzzle, direction, tilesToMove)
    print("Starting movement algorithm x: " .. direction.x .. " y: " .. direction.y)
    -- prettyPrint(puzzle:getLockedPositions())

    local blankPosition = puzzle:getPosition(0)

    local oppositeDirection
    if direction == LEFT or direction == RIGHT then
        if direction == LEFT then
            oppositeDirection = RIGHT
        else
            oppositeDirection = LEFT
        end
    end
    
    if direction == UP or direction == DOWN then
        if direction == DOWN then
            oppositeDirection = UP
        else
            oppositeDirection = DOWN
        end
    end

    local function getReturnDirection()
        if direction == LEFT or direction == RIGHT then
            if blankPosition.y >= puzzle:getBoardSize() then
                return {UP, DOWN}
            end
            return {DOWN, UP}
        end

        if direction == UP or direction == DOWN then
            if blankPosition.x >= puzzle:getBoardSize() then
                return {LEFT, RIGHT}
            end
            return {RIGHT, LEFT}
        end
        
    end

    if tilesToMove > 1 then
        for i = 1, tilesToMove - 1 do
            print("tiles:" .. tilesToMove)
            puzzle:move(oppositeDirection, true, true)
            puzzle:move(getReturnDirection()[1], true, true)
            puzzle:move(direction, true, true)
            puzzle:move(direction, true, true)
            puzzle:move(getReturnDirection()[2], true, true)
        end   
        puzzle:move(oppositeDirection, true, true)
    elseif tilesToMove == 1 then
        puzzle:move(oppositeDirection, true, true)
    end
end

function moveX(puzzle, onePosition, desiredPosition, tileValue)
    print("STARTING HORIZONTAL MOVEMENT")
    if onePosition.x == desiredPosition.x then
        print("NO HORIZONTAL MOVEMENT NEEDED")
        return puzzle
    end

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
    local desiredPosition = puzzle:getGoals(tileValue)[tileValue]
    local horizontalDirection
    if isRightOf(onePosition, desiredPosition) then
        horizontalDirection = LEFT
        print("ITLEFT")
    else
        horizontalDirection = RIGHT
        print("ITRIGHT")
    end
    

    local tilesToMove = math.abs(onePosition.x - desiredPosition.x)

    moveAlgorithm(puzzle, horizontalDirection, tilesToMove)
    return puzzle
end

function moveY(puzzle, onePosition, desiredPosition, tileValue)
    print("STARTING VERTICAL MOVEMENT")
    if onePosition.y == desiredPosition.y then
        print("NO VERTICAL MOVEMENT NEEDED")
        return puzzle
    end

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
    local desiredPosition = puzzle:getGoals(tileValue)[tileValue]
    local verticalDirection
    if isAbove(onePosition, desiredPosition) then
        verticalDirection = DOWN
        print("ITUP")
    else
        verticalDirection = UP
        print("ITDOWN")
    end

    local tilesToMove = math.abs(onePosition.y - desiredPosition.y)

    moveAlgorithm(puzzle, verticalDirection, tilesToMove)
    return puzzle
end

function solve(puzzle, onePosition, desiredPosition, tileValue, horizontalMovementFirst)

    print("SOLVING ", tileValue, "TO", desiredPosition.x, desiredPosition.y)
    puzzle:prettyPrint()
    
    if onePosition.x ~= desiredPosition.x or onePosition.y ~= desiredPosition.y then

        local horizontalMovementFirst
        if desiredPosition.x <= 2 then
            horizontalMovementFirst = false
        else
            horizontalMovementFirst = true
        end

        if (horizontalMovementFirst == true) then
            local onePosition = puzzle:getPosition(tileValue);
            local desiredPosition = puzzle:getGoals(tileValue)[tileValue]

            puzzle = moveX(puzzle, onePosition, desiredPosition, tileValue)
        
            local onePosition = puzzle:getPosition(tileValue);
            local desiredPosition = puzzle:getGoals(tileValue)[tileValue]
        
            puzzle = moveY(puzzle, onePosition, desiredPosition, tileValue)
        else
            local onePosition = puzzle:getPosition(tileValue);
            local desiredPosition = puzzle:getGoals(tileValue)[tileValue]

            puzzle = moveY(puzzle, onePosition, desiredPosition, tileValue)
        
            local onePosition = puzzle:getPosition(tileValue);
            local desiredPosition = puzzle:getGoals(tileValue)[tileValue]
        
            puzzle = moveX(puzzle, onePosition, desiredPosition, tileValue)
        end
    
    end
    print("tile value: " .. tileValue)
    puzzle:lockPosition(desiredPosition.x, desiredPosition.y)
    return puzzle
end

local state = {
    {   6,   2,  19,  16,  15 },
    {  22,  12,  23,  17,  13 },
    {   9,   5,   0,   7,  14 },
    {  24,   8,   1,  21,  20 },
    {  10,  18,   4,   3,  11 }
}
local state = {
    {  10,  22,  19,  16,  11 },
    {  12,   9,   2,  21,  14 },
    {  23,  13,   3,   5,   4 },
    {   1,   0,  15,  18,   7 },
    {   6,  20,   8,  24,  17 },
}

local state = {
    {  16,   0,  11,   4,   5 },
    {  17,   1,  14,  23,  18 },
    {   7,  19,  10,  24,  15 },
    {   6,   2,   9,  21,   8 },
    {  22,  20,  12,   3,  13 },
}


local puzzle = Puzzle:new(5, state)
puzzle:generateWinningString()
puzzle:shuffle()

print("Starting position")
puzzle:prettyPrint()

-- prettyPrint(puzzle:getLockedPositions())
puzzle:prettyPrint()
local puzzle = solve(puzzle, puzzle:getPosition(1), puzzle:getGoals()[1], 1)
puzzle = solve(puzzle, puzzle:getPosition(2), puzzle:getGoals()[2], 2)
prettyPrint(puzzle:getLockedPositions())
puzzle:prettyPrint()

puzzle = solve(puzzle, puzzle:getPosition(3), puzzle:getGoals()[3], 3)
prettyPrint(puzzle:getLockedPositions())
puzzle:prettyPrint()

-- Switch to a modified goals state so that we place the 4 and 5 in a specific way to solve them (for a 5x5 puzzle, but this example applies for all sizes). The location of those two tiles is all that matters
local newGoals = puzzle:getGoals()
-- This is modifying the goals table so that our algorithm 
newGoals[puzzle:getBoardSize() - 1] = {y = 1, x = puzzle:getBoardSize()}
newGoals[puzzle:getBoardSize()] = {y = 2, x = puzzle:getBoardSize()}

local value = 5
local location = puzzle:getPosition(value)
if location.y == 1 then
    print("NEED TO MOVE " .. value .. " OUT OF THE WAY")
    local newLocation = {x = location.x, y = location.y + math.floor(puzzle:getBoardSize() / 2)}
    local priorGoal = puzzle:getGoals()[value]
    -- change goal so we can move the 5 out of the way
    newGoals[value] = newLocation
    puzzle = solve(puzzle, puzzle:getPosition(value), puzzle:getGoals()[value], value)
    -- fix goal position back to normal
    newGoals[value] = priorGoal
    -- remove the lock that gets placed
    puzzle:unlock(newLocation.x, newLocation.y)
end

puzzle = solve(puzzle, puzzle:getPosition(4), puzzle:getGoals()[4], 4)
-- prettyPrint(puzzle:getLockedPositions())
puzzle:prettyPrint()
puzzle = solve(puzzle, puzzle:getPosition(5), puzzle:getGoals()[5], 5)
-- prettyPrint(puzzle:getLockedPositions())
puzzle:prettyPrint()

-- Get the directions to move the 0 to x = boardSize - 1, and y = 1 to move the 4 and 5 (in a 5x5) into place
local directions, movedPuzzle = pathBlankToPosition(puzzle, {x = puzzle:getBoardSize() - 1, y = 1})
puzzle = movedPuzzle
print("STARTINGqqq")
puzzle:prettyPrint()
prettyPrint(puzzle:getLockedPositions())

puzzle:unlock(puzzle:getBoardSize(), 1)
puzzle:unlock(puzzle:getBoardSize(), 2)
puzzle:move(RIGHT, false, true)
puzzle:move(DOWN, false, true)
puzzle:lockPosition(puzzle:getBoardSize() - 1, 1)
puzzle:lockPosition(puzzle:getBoardSize(), 1)

puzzle = solve(puzzle, puzzle:getPosition(6), puzzle:getGoals()[6], 6)
-- print("11!!!!")

puzzle = solve(puzzle, puzzle:getPosition(11), puzzle:getGoals()[11], 11)

-- This is modifying the goals table so that our algorithm paths to the right spot
newGoals[puzzle:getBoardSize() * 3 + 1] = {y = puzzle:getBoardSize(), x = 1}
newGoals[puzzle:getBoardSize() * 4 + 1] = {y = puzzle:getBoardSize(), x = 2}

local value = 21
local location = puzzle:getPosition(value)
if location.x == 1 then
    print("NEED TO MOVE " .. value .. " OUT OF THE WAY")
    local newLocation = {x = location.x + math.floor(puzzle:getBoardSize() / 2), y = location.y}
    local priorGoal = puzzle:getGoals()[value]
    -- change goal so we can move the 5 out of the way
    newGoals[value] = newLocation
    puzzle = solve(puzzle, puzzle:getPosition(value), puzzle:getGoals()[value], value)
    -- fix goal position back to normal
    newGoals[value] = priorGoal
    -- remove the lock that gets placed
    puzzle:unlock(newLocation.x, newLocation.y)
end

puzzle = solve(puzzle, puzzle:getPosition(16), puzzle:getGoals()[16], 16)
puzzle = solve(puzzle, puzzle:getPosition(21), puzzle:getGoals()[21], 21)

local directions, movedPuzzle = pathBlankToPosition(puzzle, {x = 1, y = puzzle:getBoardSize() - 1})
puzzle = movedPuzzle

puzzle:unlock(1, puzzle:getBoardSize())
puzzle:unlock(2, puzzle:getBoardSize())
puzzle:move(DOWN, true, true)
puzzle:move(RIGHT, true, true)
puzzle:lockPosition(1, puzzle:getBoardSize() - 1)
puzzle:lockPosition(1, puzzle:getBoardSize())

puzzle = solve(puzzle, puzzle:getPosition(7), puzzle:getGoals()[7], 7)
puzzle = solve(puzzle, puzzle:getPosition(8), puzzle:getGoals()[8], 8)

local value = 10
local location = puzzle:getPosition(value)
if location.y == 2 then
    print("NEED TO MOVE " .. value .. " OUT OF THE WAY")
    local newLocation = {x = location.x, y = location.y + math.floor(puzzle:getBoardSize() / 2)}
    local priorGoal = puzzle:getGoals()[value]
    -- change goal so we can move the 5 out of the way
    newGoals[value] = newLocation
    puzzle = solve(puzzle, puzzle:getPosition(value), puzzle:getGoals()[value], value)
    -- fix goal position back to normal
    newGoals[value] = priorGoal
    -- remove the lock that gets placed
    puzzle:unlock(newLocation.x, newLocation.y)
end

-- This is modifying the goals table so that our algorithm paths to the right spot
newGoals[puzzle:getBoardSize() * 2 -1] = {y = 2, x = puzzle:getBoardSize()}
newGoals[puzzle:getBoardSize() * 2] = {y = 3, x = puzzle:getBoardSize()}

puzzle = solve(puzzle, puzzle:getPosition(9), puzzle:getGoals()[9], 9)
puzzle = solve(puzzle, puzzle:getPosition(10), puzzle:getGoals()[10], 10)

local directions, movedPuzzle = pathBlankToPosition(puzzle, {x = puzzle:getBoardSize() - 1, y = 2})
puzzle = movedPuzzle

puzzle:unlock(puzzle:getBoardSize(), 2)
puzzle:unlock(puzzle:getBoardSize(), 3)
puzzle:move(RIGHT, true, true)
puzzle:move(DOWN, true, true)
puzzle:lockPosition(puzzle:getBoardSize() - 1, 2)
puzzle:lockPosition(puzzle:getBoardSize(), 2)
puzzle:prettyPrint()

puzzle = solve(puzzle, puzzle:getPosition(12), puzzle:getGoals()[12], 12)

local value = 22
local location = puzzle:getPosition(value)
if location.x == 2 then
    print("NEED TO MOVE " .. value .. " OUT OF THE WAY")
    local newLocation = {x = location.x + math.floor(puzzle:getBoardSize() / 2), y = location.y}
    local priorGoal = puzzle:getGoals()[value]
    -- change goal so we can move the 5 out of the way
    newGoals[value] = newLocation
    puzzle = solve(puzzle, puzzle:getPosition(value), puzzle:getGoals()[value], value)
    -- fix goal position back to normal
    newGoals[value] = priorGoal
    -- remove the lock that gets placed
    puzzle:unlock(newLocation.x, newLocation.y)
end

-- This is modifying the goals table so that our algorithm paths to the right spot
newGoals[puzzle:getBoardSize() * 3 + 2] = {y = puzzle:getBoardSize(), x = 2}
newGoals[puzzle:getBoardSize() * 4 + 2] = {y = puzzle:getBoardSize(), x = 3}

puzzle = solve(puzzle, puzzle:getPosition(17), puzzle:getGoals()[17], 17)
puzzle = solve(puzzle, puzzle:getPosition(22), puzzle:getGoals()[22], 22)

local directions, movedPuzzle = pathBlankToPosition(puzzle, {x = 2, y = puzzle:getBoardSize() - 1})
puzzle = movedPuzzle

puzzle:unlock(2, puzzle:getBoardSize())
puzzle:unlock(3, puzzle:getBoardSize())
puzzle:move(DOWN, true, true)
puzzle:move(RIGHT, true, true)
puzzle:lockPosition(2, puzzle:getBoardSize())
puzzle:lockPosition(2, puzzle:getBoardSize())
puzzle:prettyPrint()

new_array = {}
for i = 1, 3 do
    new_array[i] = {}
    for j = 1, 3 do
        new_array[i][j] = 0
    end
end

local original_array = puzzle:getBoard()
-- Map and fill the new array
for i = 1, 3 do
    for j = 1, 3 do
        if original_array[2+i][2+j] == 0 then
            new_array[i][j] = 9  -- Map 0 to 9
        else
            new_array[i][j] = original_array[2+i][2+j]
        end
    end
end

-- Print the new 3x3 array
for i = 1, 3 do
    for j = 1, 3 do
        io.write(new_array[i][j], " ")
    end
    print()
end














-- -- This is modifying the goals table so that our algorithm 


-- puzzle = solve(puzzle, puzzle:getPosition(16), puzzle:getGoals()[16], 16)

-- puzzle = solve(puzzle, puzzle:getPosition(8), puzzle:getGoals()[8], 8)

-- -- This is modifying the goals table so that our algorithm 
-- newGoals[puzzle:getBoardSize()* 2 - 1] = {y = 2, x = puzzle:getBoardSize()}
-- newGoals[puzzle:getBoardSize() * 2] = {y = 3, x = puzzle:getBoardSize()}

-- puzzle = solve(puzzle, puzzle:getPosition(9), puzzle:getGoals()[9], 9)
-- puzzle = solve(puzzle, puzzle:getPosition(10), puzzle:getGoals()[10], 10)

-- -- Get the directions to move the 0 to x = boardSize - 1, and y = 1 to move the 4 and 5 (in a 5x5) into place
-- local directions, _ = pathBlankToPosition(puzzle, {x = puzzle:getBoardSize() - 1, y = 2})
-- for i = #directions, 1, -1 do
--     print("STARTING")
--     local dir = directions[i]
--     if dir == "LEFT" then
--         puzzle:move(LEFT)
--     elseif dir == "RIGHT" then
--         puzzle:move(RIGHT)
--     elseif dir == "UP" then
--         puzzle:move(UP)
--     elseif dir == "DOWN" then
--         puzzle:move(DOWN)
--     end
-- end

-- -- Unlock n - 1 temporarily
-- puzzle:unlock(puzzle:getBoardSize() - 1, 2)
-- puzzle:move(RIGHT)
-- puzzle:move(DOWN)
-- puzzle:lockPosition(puzzle:getBoardSize() - 1, 2)

-- puzzle = solve(puzzle, puzzle:getPosition(11), puzzle:getGoals()[11], 11)

-- This is modifying the goals table so that our algorithm 
-- newGoals[puzzle:getBoardSize() * 3 + 1] = {y = puzzle:getBoardSize(), x = 1}
-- newGoals[puzzle:getBoardSize() * 4 + 1] = {y = puzzle:getBoardSize(), x = 2}

-- prettyPrint(puzzle:getLockedPositions())
-- puzzle = solve(puzzle, puzzle:getPosition(16), puzzle:getGoals()[16], 16)
-- puzzle = solve(puzzle, puzzle:getPosition(21), puzzle:getGoals()[21], 21)

-- Get the directions to move the 0 to x = boardSize - 1, and y = 1 to move the 4 and 5 (in a 5x5) into place
-- for i = #directions, 1, -1 do
--     print("STARTING")
--     local dir = directions[i]
--     if dir == "LEFT" then
--         puzzle:move(LEFT)
--     elseif dir == "RIGHT" then
--         puzzle:move(RIGHT)
--     elseif dir == "UP" then
--         puzzle:move(UP)
--     elseif dir == "DOWN" then
--         puzzle:move(DOWN)
--     end
-- end

