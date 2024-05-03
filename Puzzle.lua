
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
            table.insert(stateArray, self.board[y][x])
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

    for iy, row in ipairs(self.board) do
        for ix, col in ipairs(row) do
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

    for index, item in ipairs(valuesInTargetRows) do
        for index2, item2 in ipairs(valuesInTargetRows) do
            if item.currentPosition.y == item2.currentPosition.y then
                -- if the current positions are different relative directions than desired positions, linear conflict
                if isRightOf(item.currentPosition, item2.currentPosition) and isLeftOf(item.desiredPosition, item2.desiredPosition) then
                    -- print(item.value, " and ", item2.value, " are in conflict")
                    h = h + 2
                end
            end
        end
    end

    for index, item in ipairs(valuesInTargetCols) do
        for index2, item2 in ipairs(valuesInTargetCols) do
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

function Puzzle:hash(group)
    local boardSize = self.boardSize
    if not group or next(group) == nil then
        group = {}
        for s = 0, boardSize * boardSize - 1 do
            group[s] = true
        end
    end

    local hashString = {}
    for i = 1, boardSize do
        for j = 1, boardSize do
            local idx = self.board[i][j]
            if group[idx] then
                hashString[2 * idx + 1] = tostring(i - 1)  -- converting index and adjusting by -1 to match Python's 0-based indexing
                hashString[2 * idx + 2] = tostring(j - 1)  -- same adjustment for columns
            else
                hashString[2 * idx + 1] = 'x'
                hashString[2 * idx + 2] = 'x'
            end
        end
    end

    -- Removing 'x' characters and concatenating the string
    local cleanHashString = {}
    for k, v in ipairs(hashString) do
        if v ~= 'x' then
            table.insert(cleanHashString, v)
        end
    end

    return table.concat(cleanHashString)
end

return Puzzle