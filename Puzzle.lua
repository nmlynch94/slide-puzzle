require('util')
require('idastar')
math.randomseed(os.time())

-- constants
INF = 100000

UP = {y = -1, x = 0, direction = "UP"}
DOWN = {y = 1, x = 0, direction = "DOWN"}
LEFT = {y = 0, x =-1 , direction = "LEFT"}
RIGHT = {y = 0, x = 1, direction = "RIGHT"}

DIRECTIONS = {UP, DOWN, LEFT, RIGHT}

local Puzzle = {}

function Puzzle:new(boardSize, initialState)
    local instance = {}
    setmetatable(instance, {__index = self})

    instance.boardSize = boardSize or 3
    instance.board = {}
    instance.blankPos = {x = boardSize, y = boardSize}
    instance.directions = {}
    instance.count = 0
    instance.correlation_id = os.time(os.date("!*t"))

    -- set blank position from the given initial state
    if initialState ~= nil then
        for iy = 1, #initialState do
            local row = initialState[iy]
            for ix = 1, #row do
                local colVal = row[ix]
                if colVal == 0 then
                    instance.blankPos = {x = ix, y = iy}
                    goto continue_blank_init                    
                end
            end
        end
    end
    ::continue_blank_init::

    instance.lockedPositions = {}

    -- Generate a reverse index to make finding desired position by value easier in the heuristic check
    -- Generate a board first in a solved state so we can create a reverse-index
    for y = 1, boardSize do
        table.insert(instance.board, {})
        for x = 1, boardSize do
            instance.board[y][x] = x + (y-1) * boardSize
        end
    end
    instance.board[boardSize][boardSize] = 0

    instance.goals = {}
    for iy, row in ipairs(instance.board) do
        for ix, col in pairs(row) do
            instance.goals[col] = {x = ix, y = iy}
        end
    end

    -- Override the default solved state with the initial state provided
    if initialState ~= nil then
        instance.board = initialState
    end

    return instance
end

-- Find manhattan distance for the blank tile compared to a given position
function Puzzle:blankManhattan(x, y)
    local blankPosition = self.getPosition(self, 0)
    local manhattanDistance = math.abs(blankPosition.x - x) + math.abs(blankPosition.y - y)
    return manhattanDistance
end

function Puzzle:unlockLatest()
    print("Lockedpositions")
    prettyPrint(self.lockedPositions)
    table.remove(self.lockedPositions)
end

function Puzzle:getLockedPositions()
    return self.lockedPositions
end

function Puzzle:lockByValue(tileValue)
    local position = self:getPosition(tileValue)
    table.insert(self.lockedPositions, {x = position.x, y = position.y})
end

function Puzzle:unlockByValue(tileValue)
    local tilePosition = self:getPosition(tileValue)
    for i, position in pairs(self.lockedPositions) do
        if tilePosition.x == position.x and tilePosition.y == position.y then
            table.remove(self.lockedPositions, i)
        end
    end
end

function Puzzle:unlock(x, y)
    for i, position in pairs(self.lockedPositions) do
        if position.x == x and position.y == y then
            table.remove(self.lockedPositions, i)
        end
    end
end

-- Lua passes by reference, so we use this to 
-- clone separate puzzle objects that we can simulate moves on
-- without modifying the original state
function Puzzle:clone()
    local copy = Puzzle:new(self.boardSize)  -- This sets up a new Puzzle instance with the same board size.
    for y = 1, self.boardSize do
        for x = 1, self.boardSize do
            copy.board[y][x] = self.board[y][x]  -- Deep copy of the board.
        end
    end
    copy.blankPos = {x = self.blankPos.x, y = self.blankPos.y}  -- Copy of the blank position.
    copy.winningPuzzleString = self.winningPuzzleString  -- Copy the string if needed.
    copy.goals = self.goals
    copy.directions = self.directions
    copy.count = self.count
    copy.correlation_id = self.correlation_id

    copy.lockedPositions = self.lockedPositions

    return copy
end

-- Perform a move on a cloned state so we can analyze the output position
function Puzzle:simulateMove(dir)
    local simPuzzle = self.clone(self)
    local moveSuccessful = simPuzzle:move(dir, false, false, false)
    return moveSuccessful, simPuzzle
end

function Puzzle:increment()
    self.count = self.count + 1
    return self.count
end

function Puzzle:getGoals()
    return self.goals
end

-- Generate a winning string we can easily check against once our
-- path finding is complete
function Puzzle:generateWinningString()
    local tempBoard = {}
    for y = 1, self.boardSize do
        table.insert(tempBoard, {})
        for x = 1, self.boardSize do
            tempBoard[y][x] = math.floor(tonumber(x + (y-1) * self.boardSize))
        end
    end
    tempBoard[self.boardSize][self.boardSize] = 0

    local stateArray = {}
    for y = 1, self.boardSize do
        for x = 1, self.boardSize do
            table.insert(stateArray, tempBoard[y][x])
        end
    end
    stateArray[#stateArray] = 0
    self.winningPuzzleString = table.concat(stateArray, "-")
    return self
end

function Puzzle:getWinningString()
    return self.winningPuzzleString
end

function Puzzle:getBoardSize()
    return self.boardSize
end

function Puzzle:serializeGroup(group, replaceBlank)
    local stateArray = {}
    for y = 1, self.boardSize do
        for x = 1, self.boardSize do
            local numValue = math.floor(self.board[y][x])
            if (numValue == 0 and (replaceBlank == true or replaceBlank == nil)) then
                table.insert(stateArray, 99)
                goto continue
            end
            if (not has_value(numValue, group) and numValue ~= 0) then
                table.insert(stateArray, 99)
            else
                table.insert(stateArray, math.floor(self.board[y][x]))
            end
            ::continue::
        end
    end
    local stateArrayString = table.concat(stateArray, "-")
    return stateArrayString
end

-- Convert a 2d array into a one-line string separated by '-'
function Puzzle:serialize() 
    local stateArray = {}
    for y = 1, self.boardSize do
        for x = 1, self.boardSize do
            table.insert(stateArray, math.floor(self.board[y][x]))
        end
    end
    return table.concat(stateArray, "-")
end

function Puzzle:solve()
    -- solving a 5x5 is not feasible with ida* alone
    local directions
    if self.boardSize == 5 then
        directions = solveFiveByFive(self)
    else
        directions = idaStar(self)
    end

    return directions
end

-- 2d array print for easier verification in logs
function Puzzle:prettyPrint()
    for iy = 1, self.boardSize do
        local row = self.board[iy]
        local formattedRow = {}
        for _, num in ipairs(row) do
            table.insert(formattedRow, string.format("%3d", num)) -- Adjust the width as needed (here, 3 characters)
        end
        print("{ " .. table.concat(formattedRow, ", ") .. " },")
    end
end

function Puzzle:getTile(x, y)
    return self.board[y][x]
end

function Puzzle:getPosition(value)
    for iy, row in ipairs(self.board) do
        for ix, col in pairs(row) do
            if col == value then
                return {x = ix, y = iy}
            end
        end
    end
end

-- Add a way to shuffle so we can generate solvable puzzles easily by shuffling from a solved state
function Puzzle:shuffle()
    local nShuffles = 120
    for i = 1, nShuffles, 1 do
        local randomIndex = math.random(1, #DIRECTIONS)
        local direction = DIRECTIONS[randomIndex]
        self:move(direction, false, false, false)
    end
    return self
end

-- Allow is to update the goal position for a specific tile. This is 
-- To allow us to move a tile to something aside from the solved state
-- temporarily like we do to deal with some edge cases.
function Puzzle:updateGoal(tile, newPosition)
    self.goals[tile] = {x = newPosition.x, y = newPosition.y}
end

function Puzzle:getBoard()
    return self.board
end

-- Move the blank tile in a direction.
-- failOnLock controls if we should fail if we encounter a locked tile
-- We use this mainly for moveAlgorithm because it's a dumb function that is 
-- performing movements assuming no locked tiles are in the way.

-- record controls if this should be added to the move history for this puzzle
-- This is so we can avoid recording simulated moves or shuffling the puzzle
function Puzzle:move(direction, debug, failOnLock, record)
    if record == nil then
        record = true
    end
    if failOnLock == nil then
        failOnLock = true
    end
    if debug == nil then
        debug = false
    end
    if  false  then
        print("Moving....", direction.x, direction.y)

        self:prettyPrint()
        print("            |")
        print("            |")
        print("            V")
    end

    local newBlankPosition = {x = self.blankPos.x + direction.x, y = self.blankPos.y + direction.y}
    
    if newBlankPosition.x < 1 
    or newBlankPosition.y > self.boardSize 
    or newBlankPosition.x > self.boardSize 
    or newBlankPosition.y < 1 then    
        return false
    end

    for i = 1, #self.lockedPositions do
        if self.lockedPositions[i].x == newBlankPosition.x and self.lockedPositions[i].y == newBlankPosition.y then
            if failOnLock then
                error("Lock encountered when we didn't expect it")
            end
            return false
        end
    end

    self.board[self.blankPos.y][self.blankPos.x] = self.board[newBlankPosition.y][newBlankPosition.x]
    self.board[newBlankPosition.y][newBlankPosition.x] = 0
    self.blankPos = newBlankPosition

    if false then
        self:prettyPrint()
        print("--------------")
    end
    if record then
        table.insert(self.directions, {direction = direction.direction})
    end
    return true
end

function Puzzle:removeLocks()
    self.lockedPositions = {}
end

function Puzzle:printDirections()
    for  i = 1, #self.directions do
        print(self.directions[i].direction)
    end
end

function Puzzle:getDirections()
    return self.directions
end

function Puzzle:checkWin()
    return self.serialize(self) == self.winningPuzzleString
end

function Puzzle:playDirections(directions)
    for i = 1, #directions do
        local dir = directions[i].direction
        if dir == "LEFT" then
            self:move(LEFT, false)
        elseif dir == "RIGHT" then
            self:move(RIGHT, false)
       elseif dir == "UP" then
            self:move(UP, false)
        elseif dir == "DOWN" then
            self:move(DOWN, false)
        else
            prettyPrint(dir)
            error("Wrong direction passed")
        end
    end
    return self
end

function Puzzle:getHeuristic()
    local h = 0
    local valuesInTargetRows = {}
    local valuesInTargetCols = {}

    for iy = 1, #self.board do
        local row = self.board[iy]
        for ix = 1, #row do
            local col = row[ix]
            if col == 0 then goto continue_h end -- We don't care about manhattan for the blank tile
            local desiredPosition = self.goals[col]
            local currentPosition = {x = ix, y = iy}
            if desiredPosition.y == currentPosition.y then
                table.insert(valuesInTargetRows, {currentPosition = currentPosition, desiredPosition = desiredPosition, value = col})
            end
            if desiredPosition.x == currentPosition.x then
                table.insert(valuesInTargetCols, {currentPosition = currentPosition, desiredPosition = desiredPosition, value = col})
            end
            local manhattan = math.abs(desiredPosition.x - currentPosition.x) + math.abs(desiredPosition.y - currentPosition.y)
            h = h + manhattan
            ::continue_h::
        end
    end

    -- Loop through all values that are currently in their target rows and compare it with every other value. 
    -- If valueA's current position is left of valueBs current position, and valueA's desired position is right of valueB's desired position
    -- then that means they are a linear conflict. We only check for left/right vs right/left so it doesn't double-count a conflict
    for index = 1, #valuesInTargetRows do
        local item = valuesInTargetRows[index]
        for index2 = 1, #valuesInTargetRows do
            local item2 = valuesInTargetRows[index2]
            if item.currentPosition.y == item2.currentPosition.y then
                -- if the current positions are different relative directions than desired positions, linear conflict
                if isRightOf(item.currentPosition, item2.currentPosition) and isLeftOf(item.desiredPosition, item2.desiredPosition) then
                    -- print(item.value, " and ", item2.value, " are in conflict")
                    h = h + 2
                end
            end
        end
    end

    for index = 1, #valuesInTargetCols do
        local item = valuesInTargetCols[index]
        for index2 = 1,#valuesInTargetCols do
            local item2 = valuesInTargetCols[index2]
            -- If they are in the same column AND it needs to move AND item2 is located in between
            if item.currentPosition.x == item2.currentPosition.x then
                -- if the current positions are different relative directions than desired positions, linear conflict
                if isAbove(item.currentPosition, item2.currentPosition) and isBelow(item.desiredPosition, item2.desiredPosition) then
                    -- print(item.value, " and ", item2.value, " are in conflict")
                    h = h + 2
                end
            end
        end
    end

    return h * 2
end

return Puzzle