local Puzzle = require("Puzzle")

local moveTests = {
    {
        preMoveState = {
            {4, 14, 15, 2, 22},
            {0, 23, 5, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        postMoveState = {
            {4, 14, 15, 2, 22},
            {0, 23, 5, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        direction = LEFT
    },
    {
        preMoveState = {
            {4, 14, 15, 2, 22},
            {5, 23, 0, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        postMoveState = {
            {4, 14, 15, 2, 22},
            {5, 0, 23, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        direction = LEFT
    },
    {
        preMoveState = {
            {4, 14, 15, 2, 22},
            {0, 23, 5, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        postMoveState = {
            {4, 14, 15, 2, 22},
            {23, 0, 5, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        direction = RIGHT
    },
    {
        preMoveState = {
            {4, 14, 15, 2, 22},
            {0, 23, 5, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        postMoveState = {
            {0, 14, 15, 2, 22},
            {4, 23, 5, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        direction = UP
    },
    {
        preMoveState = {
            {4, 14, 15, 2, 22},
            {0, 23, 5, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        postMoveState = {
            {4, 14, 15, 2, 22},
            {20, 23, 5, 11, 7},
            {0, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        direction = DOWN
    },
}

for index, testData in pairs(moveTests) do
    print("TEST MOVING " .. index .. " - " .. testData.direction.x .. ", " .. testData.direction.y)
    local puzzle = Puzzle:new(5, testData.preMoveState)
    puzzle:generateWinningString()
    print("State:", puzzle:serialize())
    puzzle:move(testData.direction)
    local preMoveState = puzzle:serialize()
    puzzle:prettyPrint()
    print("---------------")
    Puzzle:new(5, testData.postMoveState):prettyPrint()
    local postMoveState = Puzzle:new(5, testData.postMoveState):serialize()
    assert(preMoveState == postMoveState, preMoveState .. " ~= " .. postMoveState)
    print("------------------ END -------------------------")
end

local winningPuzzleString = "1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-0"


for i = 1, 100 do
    local puzzle = Puzzle:new(5)
    puzzle:shuffle()
    puzzle:generateWinningString()

    local initialState = puzzle:getBoard()
    assert(puzzle:serialize() ~= winningPuzzleString)
    local directions = puzzle:solve()

    -- verify the moves solve when applied to separate puzzle with the same initial state
    local puzzleToSolve = Puzzle:new(5, initialState)
    assert(puzzleToSolve:serialize() ~= winningPuzzleString)
    for i = 1, #directions do
        local dir = directions[i].direction
        if dir == "LEFT" then
            puzzleToSolve:move(LEFT)
        elseif dir == "RIGHT" then
            puzzleToSolve:move(RIGHT)
        elseif dir == "UP" then
            puzzleToSolve:move(UP)
        elseif dir == "DOWN" then
            puzzleToSolve:move(DOWN)
        else
            prettyPrint(dir)
            error("Wrong direction passed")
        end
    end
    assert(#directions < 400, "Directions are higher than expected")

    print(puzzleToSolve:serialize() .. " : " .. winningPuzzleString)
    assert(puzzleToSolve:serialize() == winningPuzzleString)
    print(#directions .. " moves")
end