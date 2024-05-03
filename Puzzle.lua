math.randomseed(os.time())

INF = 100000

UP = {-1,0, "UP"}
DOWN = {1,0, "DOWN"}
LEFT = {0,-1 ,"LEFT"}
RIGHT = {0,1, "RIGHT"}

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
    instance.blankPos = {boardSize, boardSize}

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

function Puzzle:clone()
    local copy = Puzzle:new(self.boardSize)  -- This sets up a new Puzzle instance with the same board size.
    for y = 1, self.boardSize do
        for x = 1, self.boardSize do
            copy.board[y][x] = self.board[y][x]  -- Deep copy of the board.
        end
    end
    copy.blankPos = {self.blankPos[1], self.blankPos[2]}  -- Copy of the blank position.
    copy.winningPuzzleString = self.winningPuzzleString  -- Copy the string if needed.
    
    -- Recreating goals mapping if necessary
    copy.goals = {}
    for value, pos in pairs(self.goals) do
        copy.goals[value] = {x = pos.x, y = pos.y}
    end

    return copy
end

function Puzzle:simulateMove(dir)
    local simPuzzle = self.clone(self)
    local moveSuccessful = simPuzzle:move(dir)
    return moveSuccessful, simPuzzle
end

function Puzzle:getGoals()
    return self.goals
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
        self:move(direction)
    end
end

function Puzzle:move(direction)
    local newBlankPosition = {self.blankPos[1] + direction[1], self.blankPos[2] + direction[2]}
    if newBlankPosition[1] < 1 or newBlankPosition[2] > self.boardSize or newBlankPosition[1] > self.boardSize or newBlankPosition[2] < 1 then
        return false
    end

    self.board[self.blankPos[1]][self.blankPos[2]] = self.board[newBlankPosition[1]][newBlankPosition[2]]
    self.board[newBlankPosition[1]][newBlankPosition[2]] = 0
    self.blankPos = newBlankPosition
    return true
end

function Puzzle:checkWin()
    return self.serialize(self) == self.winningPuzzleString
end

-- Any objects that have an x and y property will work here e.g. {x = 1, y = 2, ...anything else}
local function isRightOf(item1, item2)
    return item1.x > item2.x
end

local function isLeftOf(item1, item2)
    return item1.x < item2.x
end

local function isBelow(item1, item2)
    return item1.y > item2.y
end

local function isAbove(item1, item2)
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