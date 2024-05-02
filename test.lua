math.randomseed(os.time())

DIRECTIONS = {
    UP = {-1,0},
    DOWN = {1,0},
    LEFT = {0,-1},
    RIGHT = {0,1}
}

local Puzzle = {}

function Puzzle:new(boardSize, initialState)
    local instance = {}
    setmetatable(instance, {__index = self})

    instance.boardSize = boardSize or 3
    instance.board = {}
    instance.blankPos = {instance.boardSize, instance.boardSize}

    if initialState == nil then
        for y = 1, instance.boardSize do
            table.insert(instance.board, {})
            for x = 1, instance.boardSize do
                instance.board[y][x] = x + (y-1) * boardSize
            end
        end
        instance.board[boardSize][boardSize] = 0
    end
    
    return instance
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
    return table.concat(stateArray, ", ")
end

function Puzzle:getTile(x, y)
    return self.board[y][x]
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
    if newBlankPosition[1] < 1 or newBlankPosition[2] > self.boardSize then
        return false
    end

    self.board[self.blankPos[1]][self.blankPos[2]] = self.board[newBlankPosition[1]][newBlankPosition[2]]
    self.board[newBlankPosition[1]][newBlankPosition[2]] = 0
    self.blankPos = newBlankPosition
    return true
end

function Puzzle:checkWin()
    local solvedPuzzle = Puzzle:new(self.boardSize)
    local checkSum = solvedPuzzle:serialize()
    return checkSum == self.serialize(self)
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

function factorial(n)
    if n == 0 then return 1 end
    return n * factorial(n - 1)
end

function permutations(n, k)
    return factorial(n) / factorial(n - k)
end

function buildPatternDb(boardSize, group, groupNum)
    local puzzle = Puzzle:new(boardSize)
    puzzle.count = 0

    local groupWithBlank = {}
    for _, v in ipairs(group) do
        groupWithBlank[v] = true
    end
    groupWithBlank[0] = true -- Adding blank

    local visited = {}
    local closedList = {}
    local openList = {}
    local iter = 0
    local totIter = permutations(boardSize * boardSize, #groupWithBlank)
    local t1 = os.clock()

    table.insert(openList, {puzzle, {0, 0}})

    while #openList > 0 do
        local curEntry = table.remove(openList, 1) -- Dequeue
        local cur, prevMove = curEntry[1], curEntry[2]

        if not visitNode(cur, visited, closedList, groupWithBlank, group) then
            goto continue
        end

        for _, dir in ipairs(puzzle.DIRECTIONS) do
            if dir[1] == prevMove[1] and dir[2] == prevMove[2] then
                goto continue_dir
            end

            local validMove, simPuzzle = cur:simulateMove(dir)
            if not validMove then
                goto continue_dir
            end

            if groupWithBlank[simPuzzle.board[simPuzzle.blankPos[1]][simPuzzle.blankPos[2]]] then
                simPuzzle.count = simPuzzle.count + 1
            end

            table.insert(openList, {simPuzzle, {-dir[1], -dir[2]}})
            ::continue_dir::
        end
        iter = iter + 1

        if iter % 100000 == 0 then
            local t2 = os.clock()
            local tDelta = t2 - t1
            print(string.format("Group %d, Iteration %d of %d, time elapsed: %f seconds", groupNum, iter, totIter, tDelta))
            print("Size of closed list: ", #closedList)
            print("Size of open list: ", #openList)
            t1 = t2
        end
        ::continue::
    end

    return closedList
end

function visitNode(puzzle, visited, closedList, groupWithBlank, group)
    local puzzleHashWithBlank = puzzle.hash(groupWithBlank)
    if visited[puzzleHashWithBlank] ~= nil then
        return false
    end

    visited[puzzleHashWithBlank] = puzzleHashWithBlank

    local groupHash = puzzle.hash(group)

    if closedList[group] == nil then
        closedList[groupHash] = puzzle.count
    elseif closedList[groupHash] > puzzle.count then
        closedList[groupHash] = puzzle.count
    end

    return true
end

local boardSize = 4

-- 663
local groups = {{1,5,6,9,10.13},{7,8,11,12,14,15},{2,3,4}}

local closedList = {}

for index, group in pairs(groups) do
    table.insert(closedList, buildPatternDb(boardSize, group))
end

local serpent = require 'serpent'  -- Include serpent or similar library for serialization

-- Open the file for writing
local patternDbFile = io.open('patternDb_' .. tostring(boardSize) .. '.dat', 'wb')
if patternDbFile then
    patternDbFile:write(serpent.dump(groups))    -- Serialize and write groups
    patternDbFile:write(serpent.dump(closedList)) -- Serialize and write closedList
    patternDbFile:close()  -- Close the file
else
    print("Failed to open file for writing.")
end

-- Loop through closedList and print details
for i, group in ipairs(closedList) do
    print("Group:", groups[i], #group, "permutations")
end