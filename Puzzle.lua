math.randomseed(os.time())

INF = 100000

UP = {y = -1, x = 0, direction = "UP"}
DOWN = {y = 1, x = 0, direction = "DOWN"}
LEFT = {y = 0, x =-1 , direction = "LEFT"}
RIGHT = {y = 0, x = 1, direction = "RIGHT"}

DIRECTIONS = {UP, DOWN, LEFT, RIGHT}

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

local Puzzle = {}
local winningPuzzleString

function Puzzle:new(boardSize, initialState)
    local instance = {}
    setmetatable(instance, {__index = self})

    instance.boardSize = boardSize or 3
    instance.board = {}
    instance.blankPos = {x = boardSize, y = boardSize}
    instance.directions = {}

    -- get the blank position from the initial state
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

    -- Generate a board first in a solved state so we can create a reverse-index
    for y = 1, boardSize do
        table.insert(instance.board, {})
        for x = 1, boardSize do
            instance.board[y][x] = x + (y-1) * boardSize
        end
    end

    -- Reverse index to make finding desired position by value easier in the heuristic check
    instance.goals = {}
    for iy, row in ipairs(instance.board) do
        for ix, col in pairs(row) do
            instance.goals[col] = {x = ix, y = iy}
        end
    end

    if initialState ~= nil then
        instance.board = initialState
    end

    
    return instance
end

function Puzzle:blankManhattan(x, y)
    local blankPosition = self.getPosition(self, 0)
    local manhattanDistance = math.abs(blankPosition.x - x) + math.abs(blankPosition.y - y)
    return manhattanDistance
end

function Puzzle:lockPosition(x, y)
    print(x .. ", " .. y)
    table.insert(self.lockedPositions, {x = x, y = y})
end

function Puzzle:unlockLatest()
    print("Lockedpositions")
    prettyPrint(self.lockedPositions)
    table.remove(self.lockedPositions)
end

function Puzzle:getLockedPositions()
    return self.lockedPositions
end

function Puzzle:unlock(x, y)
    for i, position in pairs(self.lockedPositions) do
        if position.x == x and position.y == y then
            table.remove(self.lockedPositions, i)
        end
    end
end

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

    copy.lockedPositions = self.lockedPositions

    return copy
end

function Puzzle:simulateMove(dir)
    local simPuzzle = self.clone(self)
    local moveSuccessful = simPuzzle:move(dir, false, false, false)
    return moveSuccessful, simPuzzle
end

function Puzzle:getGoals()
    return self.goals
end

function Puzzle:setGoals(goals)
    self.goals = goals
end

function Puzzle:generateWinningString()
    local tempBoard = {}
    for y = 1, self.boardSize do
        table.insert(tempBoard, {})
        for x = 1, self.boardSize do
            tempBoard[y][x] = x + (y-1) * self.boardSize
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
end

function Puzzle:getWinningString()
    return self.winningPuzzleString
end

function Puzzle:getBoardSize()
    return self.boardSize
end

function Puzzle:serialize() 
    local stateArray = {}
    for y = 1, self.boardSize do
        for x = 1, self.boardSize do
            table.insert(stateArray, self.board[y][x])
        end
    end
    return table.concat(stateArray, "-")
end

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

function Puzzle:shuffle()
    local nShuffles = 1000
    for i = 1, nShuffles, 1 do
        local randomIndex = math.random(1, #DIRECTIONS)
        local direction = DIRECTIONS[randomIndex]
        self:move(direction, false, false, false)
    end
end

function Puzzle:getBoard()
    return self.board
end

function Puzzle:move(direction, debug, failOnLock, record)
    if record == nil then
        record = true
    end
    if failOnLock == nil then
        failOnLock = true
    end
    if debug == nil then
        debug = true
    end
    if debug then
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

    if debug then
        self:prettyPrint()
        print("--------------")
    end
    if record then
        table.insert(self.directions, {direction = direction.direction, state = self:clone()})
    end
    return true
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

-- Any objects that have an x and y property will work here e.g. {x = 1, y = 2, ...anything else}
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

    return h
end

return Puzzle