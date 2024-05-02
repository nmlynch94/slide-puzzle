math.randomseed(os.time())

INF = 100000

UP = {-1,0, "UP"}
DOWN = {1,0, "DOWN"}
LEFT = {0,-1 ,"LEFT"}
RIGHT = {0,1, "RIGHT"}

DIRECTIONS = {UP, DOWN, LEFT, RIGHT}

local Puzzle = {}
local winningPuzzleString

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

function Puzzle:new(boardSize, initialState)
    local instance = {}
    setmetatable(instance, {__index = self})

    instance.boardSize = boardSize or 3
    instance.board = {}
    instance.blankPos = {boardSize, boardSize}

    if initialState == nil then
        for y = 1, boardSize do
            table.insert(instance.board, {})
            for x = 1, boardSize do
                instance.board[y][x] = x + (y-1) * boardSize
            end
        end
        instance.board[boardSize][boardSize] = 0
    else
        instance.board = initialState
    end

    -- Reverse index to make finding desired position by value easier in the heuristic check
    instance.goals = {}
    for iy, row in ipairs(instance.board) do
        for ix, col in pairs(row) do
            instance.goals[col] = {x = ix, y = iy}
        end
    end
    
    return instance
end

function Puzzle:getGoals()
    return self.goals
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
    return winningPuzzleString == self.serialize(self)
end

function Puzzle:getHeuristic()
    local h = 0
    local valuesInTargetRows = {}
    local valuesInTargetCols = {}

    for iy, row in ipairs(self.board) do
        for ix, col in ipairs(row) do
            local desiredPosition = self.goals[col]
            local currentPosition = {x = ix, y = iy}
            if desiredPosition and currentPosition then
                if desiredPosition.y == currentPosition.y then
                    table.insert(valuesInTargetRows, {currentPosition = currentPosition, desiredPosition = desiredPosition})
                end
                if desiredPosition.x == currentPosition.x then
                    table.insert(valuesInTargetCols, {currentPosition = currentPosition, desiredPosition = desiredPosition})
                end
                h = h + math.abs(desiredPosition.x - currentPosition.x) + math.abs(desiredPosition.y - currentPosition.y)
            end
        end
    end

    for index, item in ipairs(valuesInTargetRows) do
        for index2, item2 in ipairs(valuesInTargetRows) do
            if index ~= index2 and item.desiredPosition.x < item2.desiredPosition.x and item.currentPosition.x > item2.currentPosition.x then
                h = h + 2
            end
        end
    end

    for index, item in ipairs(valuesInTargetCols) do
        for index2, item2 in ipairs(valuesInTargetCols) do
            if index ~= index2 and item.desiredPosition.y < item2.desiredPosition.y and item.currentPosition.y > item2.currentPosition.y then
                h = h + 2
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
local function h(puzzle)
    return puzzle:getHeuristic()
end

local function isPuzzleInPath(puzzle, path)
    for index, priorPuzzle in pairs(path) do
        if priorPuzzle:serialize() == puzzle:serialize() then
            return true
        end
    end
    return false
end

function Puzzle:simulateMove(dir)
    local simPuzzle = deepcopy(self)
    local moveSuccessful = simPuzzle:move(dir)
    return moveSuccessful, simPuzzle
end

local function search(path, g, bound, dirs)
    local cur = path[#path]
    local f = g + h(cur)
    print(f, cur:serialize())

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
    
        table.insert(path, simPuzzle)
        table.insert(dirs, dir)
    
        local t = search(path, g + 1, bound, dirs)
        if t == true then
            return true
        end
        if t < min then
            min = t
        end
    
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

local puzzle = Puzzle:new(4)
winningPuzzleString = puzzle:serialize()
puzzle:shuffle()
local startingPuzzleState = puzzle:serialize()

local directions = idaStar(puzzle)

print("starting puzzle state: ", startingPuzzleState)
for index, item in pairs(directions) do
    print(item[3])
end