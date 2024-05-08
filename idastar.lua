require("util")

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
        if #dirs > 0 and -dir.y == dirs[#dirs].y and -dirs[#dirs].x == -dir.x then
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

function idaStar(puzzle)
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

-- This function recursively enumerates all position states within 10 moves from the current
-- location of the blank tile. This then sorts the resulting set by h, g to find the shortest
-- path to the desired tile while avoiding locked positions in the puzzle

-- This method is feasible for moving the blank tile to one location due to the size of the space being searched,
-- but will not work for the full puzzle due to the number of available states for a 5x5
function pathBlankToPosition(puzzle, target)
    local originalPuzzle = puzzle:clone()

    local paths = {}
-- Enumerate all possible paths 10 spaces from the blank to find the one we want. Heuristic is manhattan distance.
    local function searchBruceForce(path, closedPaths, target, bound, g)
        local newMoves = {}

        -- Find all valid moves that have not been explored in the past
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

        -- search the lowest heuristic values first
        table.sort(newMoves, function (a, b) 
            return a.h < b.h
        end)

        -- If no newMoves exist, we are at a dead end
        -- If g is greater than bound, return to avoid ballooning the state we store
        if #newMoves == 0 or g > bound then
            return
        end

        -- For all new moves found, set a key on the table with the serialized puzzle value so we can easily find it in the future
        -- Add the valid newMoves to the overall list of paths to sort at the end.
        -- Call this function again on all valid states found
        for i = 1, #newMoves do
            closedPaths[newMoves[i].puzzle:serialize()] = "OCCUPIED"
            paths[#paths + 1] = newMoves[i]
            paths[newMoves[i].puzzle:serialize()] = newMoves[i]
            if newMoves[i].h > 0 then
                searchBruceForce(newMoves[i].puzzle, closedPaths, target, bound, g + 1)
            end
        end
    end

    local closedPaths = {}
    local bound = 10 -- We should be able to get anywhere we need on the board within 10 moves, so bound each path to that size
    local startingG = 0
    closedPaths[puzzle:serialize()] = "OCCUPIED"
    if puzzle:getHeuristic() > 0 then
        searchBruceForce(puzzle:clone(), closedPaths, target, bound, startingG)
    end

    -- sort all located paths by h, g
    table.sort(paths, function(a, b)
        if a.h ~= b.h then
            return a.h < b.h
        end

        return a.g < b.g
    end)

    -- Print directions in reverse order
    -- We are grabbing from paths[1] since we sorted by h, g
    -- This should be a path with h = 0 and lowest g as possible
    local cur = paths[1]
    local directions = {}

    -- Work backwards from the path to get the full route
    while cur.parent ~= nil do
        table.insert(directions, cur.direction)
        cur = cur.parent
    end
    if cur.direction then
        table.insert(directions, cur.direction)
    end

    -- Play all the moves on the main puzzle so they end up in the solution directions array
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


-- Algorithm to move a tile sideways.
-- For example, if we want to move the tile to the right of the blank tile left,
-- then we run right, down, left, left, up
-- This function decides the number of iterations to run and which direction to return in
-- based on the spacing available on the board.
function moveX(puzzle, onePosition, desiredPosition, tileValue)
    print("starting horizontal movement...")
    if onePosition.x == desiredPosition.x then
        print("no horizontal movement needed")
        return puzzle
    end

    -- Lock the tile we are pathing relative to so that we don't move it on the way
    -- to the target position and mess up our subsequent path finding algorithm
    puzzle:lockByValue(tileValue)
    if isRightOf(onePosition, desiredPosition) then
        local _, puzz = pathBlankToPosition(puzzle, {x = onePosition.x - 1, y = onePosition.y})
        puzzle = puzz
    else
        local _, puzz = pathBlankToPosition(puzzle, {x = onePosition.x + 1, y = onePosition.y})
        puzzle = puzz
    end
    puzzle:unlockByValue(tileValue)

    local onePosition = puzzle:getPosition(tileValue);
    local desiredPosition = puzzle:getGoals(tileValue)[tileValue]
    local horizontalDirection
    if isRightOf(onePosition, desiredPosition) then
        horizontalDirection = LEFT
    else
        horizontalDirection = RIGHT
    end
    

    local tilesToMove = math.abs(onePosition.x - desiredPosition.x)

    moveAlgorithm(puzzle, horizontalDirection, tilesToMove)
    return puzzle
end

function moveY(puzzle, onePosition, desiredPosition, tileValue)
    print("starting vertical movement...")
    if onePosition.y == desiredPosition.y then
        print("no vertical movement needed")
        return puzzle
    end

    -- Lock the tile we are pathing relative to so that we don't move it on the way
    -- to the target position and mess up our subsequent path finding algorithm
    puzzle:lockByValue(tileValue)
    if isAbove(onePosition, desiredPosition) then
        local _, puzz = pathBlankToPosition(puzzle, {x = onePosition.x, y = onePosition.y + 1})
        puzzle = puzz
    else
        local _, puzz = pathBlankToPosition(puzzle, {x = onePosition.x, y = onePosition.y - 1})
        puzzle = puzz    
    end
    puzzle:unlockByValue(tileValue)

    local onePosition = puzzle:getPosition(tileValue);
    local desiredPosition = puzzle:getGoals(tileValue)[tileValue]
    local verticalDirection
    if isAbove(onePosition, desiredPosition) then
        verticalDirection = DOWN
    else
        verticalDirection = UP
    end

    local tilesToMove = math.abs(onePosition.y - desiredPosition.y)

    moveAlgorithm(puzzle, verticalDirection, tilesToMove)
    return puzzle
end

function solve(puzzle, tileValue)

    local currentPosition = puzzle:getPosition(tileValue)
    local desiredPosition = puzzle:getGoals()[tileValue]

    print("Moving ", tileValue, "to", desiredPosition.x, desiredPosition.y)
    
    if currentPosition.x ~= desiredPosition.x or currentPosition.y ~= desiredPosition.y then

        local horizontalMovementFirst
        if desiredPosition.x <= 2 and desiredPosition.y > 2 then
            horizontalMovementFirst = false
        else
            horizontalMovementFirst = true
        end

        if (horizontalMovementFirst == true) then
            local currentPosition = puzzle:getPosition(tileValue);
            local desiredPosition = puzzle:getGoals(tileValue)[tileValue]

            puzzle = moveX(puzzle, currentPosition, desiredPosition, tileValue)
        
            local currentPosition = puzzle:getPosition(tileValue);
            local desiredPosition = puzzle:getGoals(tileValue)[tileValue]
        
            puzzle = moveY(puzzle, currentPosition, desiredPosition, tileValue)
        else
            local currentPosition = puzzle:getPosition(tileValue);
            local desiredPosition = puzzle:getGoals(tileValue)[tileValue]

            puzzle = moveY(puzzle, currentPosition, desiredPosition, tileValue)
        
            local currentPosition = puzzle:getPosition(tileValue);
            local desiredPosition = puzzle:getGoals(tileValue)[tileValue]
        
            puzzle = moveX(puzzle, currentPosition, desiredPosition, tileValue)
        end
    
    end
    -- Once we solve the value, lock it so it can't move
    puzzle:lockByValue(tileValue)
    return puzzle
end

-- When solving cols n, or n - 1 they need to be placed in a specific way first. This function achieves that and also addresses some edge cases https://www.kopf.com.br/kaplof/how-to-solve-any-slide-puzzle-regardless-of-its-size/
local function solveEdge(puzzle, tileValueOne, tileValueTwo)
    -- Switch to a modified goals state so that we place the 4 and 5 in a specific way to solve them (for a 5x5 puzzle, but this example applies for all sizes). The location of those two tiles is all that matters
    local currentGoalPositionTileOne = puzzle:clone():getGoals()[tileValueOne]
    local boardSize = puzzle:getBoardSize()

    local solvingHorizontalEdge
    if currentGoalPositionTileOne.x > 3 then solvingHorizontalEdge = true else solvingHorizontalEdge = false end

    local location = puzzle:getPosition(tileValueTwo)
    local needToMoveOutOfTheWay = false
    if (solvingHorizontalEdge and location.x > 3 and location.y < 4) or (not solvingHorizontalEdge and location.y > 3 and location.x < 4) then needToMoveOutOfTheWay = true end
    
    -- There are cases where the blank can get caught between two locked tiles
    -- This is to move the tile out of the way first as a lazy way to avoid it
    if needToMoveOutOfTheWay then
        print("Need to move " .. tileValueTwo .. " out of the way")
        local xModifier = 0
        local yModifier = 0
        if solvingHorizontalEdge then yModifier = 3 else xModifier = 3 end
        local newLocation = {x = location.x + xModifier, y = location.y + yModifier}
        local priorGoal = puzzle:clone():getGoals()[tileValueTwo]
        -- change goal so we can move the 5 out of the way
        puzzle:updateGoal(tileValueTwo, newLocation)
        puzzle = solve(puzzle, tileValueTwo)
        -- fix goal position back to normal
        puzzle:updateGoal(tileValueTwo, priorGoal)
        -- remove the lock that gets placed by solve
        puzzle:unlockByValue(tileValueTwo)
    end

    if solvingHorizontalEdge then -- We are solving a horizontal edge
        puzzle:updateGoal(tileValueOne, {x = boardSize, y = currentGoalPositionTileOne.y})
        puzzle:updateGoal(tileValueTwo, {x = boardSize, y = currentGoalPositionTileOne.y + 1})
    else -- We are solving a vertical edge
        puzzle:updateGoal(tileValueOne, {x = currentGoalPositionTileOne.x, y = boardSize})
        puzzle:updateGoal(tileValueTwo, {x = currentGoalPositionTileOne.x + 1, y = boardSize})
    end

    puzzle = solve(puzzle, tileValueOne)
    puzzle:prettyPrint()
    puzzle = solve(puzzle, tileValueTwo)

    local targetBlankPosition
    if solvingHorizontalEdge then
        targetBlankPosition = {x = puzzle:getBoardSize() - 1, y = currentGoalPositionTileOne.y}
    else
        targetBlankPosition = {x = currentGoalPositionTileOne.x, y = puzzle:getBoardSize() - 1}
    end

    local _, movedPuzzle = pathBlankToPosition(puzzle, targetBlankPosition)
    puzzle = movedPuzzle

    puzzle:unlockByValue(tileValueOne)
    puzzle:unlockByValue(tileValueTwo)
    if solvingHorizontalEdge then
        puzzle:move(RIGHT, false, true)
        puzzle:move(DOWN, false, true)
    else
        puzzle:move(DOWN, false, true)
        puzzle:move(RIGHT, false, true)
    end
    puzzle:lockByValue(tileValueOne)
    puzzle:lockByValue(tileValueTwo)

    return puzzle
end

local function solve4by4(puzzle, boardSize)
    -- Map the appropriate 5x5 values to corresponding 3x3 values
    local fiveByFiveToThreeByThreeMap = {}
    fiveByFiveToThreeByThreeMap[7] = 1
    fiveByFiveToThreeByThreeMap[8] = 2
    fiveByFiveToThreeByThreeMap[9] = 3
    fiveByFiveToThreeByThreeMap[10] = 4
    fiveByFiveToThreeByThreeMap[12] = 5
    fiveByFiveToThreeByThreeMap[13] = 6
    fiveByFiveToThreeByThreeMap[14] = 7
    fiveByFiveToThreeByThreeMap[15] = 8
    fiveByFiveToThreeByThreeMap[17] = 9
    fiveByFiveToThreeByThreeMap[18] = 10
    fiveByFiveToThreeByThreeMap[19] = 11
    fiveByFiveToThreeByThreeMap[20] = 12
    fiveByFiveToThreeByThreeMap[22] = 13
    fiveByFiveToThreeByThreeMap[23] = 14
    fiveByFiveToThreeByThreeMap[24] = 15
    fiveByFiveToThreeByThreeMap[0] = 0

    local valueMap = fiveByFiveToThreeByThreeMap


    local fourByFour = {}
    for i = 1, 4 do
        table.insert(fourByFour, {})
        for j = 1, 4 do
            table.insert(fourByFour[i], 0)
        end
    end
    prettyPrint(fourByFour)


    local board = puzzle:getBoard()
    for iy = 2, #board do
        for ix = 2, #board[iy] do
            fourByFour[iy - 1][ix - 1] = valueMap[board[iy][ix]]
        end
    end
    prettyPrint(fourByFour)

    local fourByFourPuzzle = puzzle:new(4, fourByFour)
    fourByFourPuzzle:generateWinningString()
    fourByFourPuzzle:prettyPrint()

    -- Play the moves on the main puzzle so it appears in our directions logs
    local directions = idaStar(fourByFourPuzzle)
    for i = 1, #directions do
        local dir = directions[i].direction
        if dir == "LEFT" then
            puzzle:move(LEFT)
        elseif dir == "RIGHT" then
            puzzle:move(RIGHT)
        elseif dir == "UP" then
            puzzle:move(UP)
        elseif dir == "DOWN" then
            puzzle:move(DOWN)
        end
    end
    return puzzle
end

function solveFiveByFive(puzzle)
    local before = os.clock()
    puzzle:generateWinningString() -- make sure the winning string is generated
    local startingPosition = puzzle:serialize()

    local puzzle = solve(puzzle, 1)
    puzzle = solve(puzzle, 2)
    puzzle = solve(puzzle, 3)
    puzzle = solveEdge(puzzle, 4, 5)
    puzzle = solve(puzzle, 6)
    puzzle = solve(puzzle, 11)
    puzzle = solveEdge(puzzle, 16, 21)
    -- puzzle = solve(puzzle, 7)
    -- puzzle = solve(puzzle, 8)
    -- puzzle = solveEdge(puzzle, 9, 10)
    -- puzzle = solve(puzzle, 12)
    -- puzzle = solveEdge(puzzle, 17, 22)

    puzzle = solve4by4(puzzle)
    -- assert(puzzle:serialize() == "1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-0")

    -- statistics
    local directions = puzzle:getDirections()
    local after = os.clock()
 
    local output = string.format("%0.6f seconds," .. #directions .. " moves in state " .. puzzle:serialize() .. " starting: " .. startingPosition, after - before)
    print(output)
    return directions
end