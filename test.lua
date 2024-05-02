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

local puzzle = Puzzle:new(4)
print(puzzle:move(DIRECTIONS.RIGHT))
print(puzzle:serialize())
