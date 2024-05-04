local Puzzle = require("Puzzle")
local idastar = require("idastar")


local stateB = {
    {4, 14, 15, 2, 22},
    {0, 23, 5, 11, 7},
    {20, 3, 12, 6, 17},
    {18, 19, 24, 8, 16},
    {13, 10, 1, 9, 21}
}

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
    print("TEST MOVING " .. testData.direction.x .. ", " .. testData.direction.y)
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

local blankManhattanTest = {
    {
        state = {
            {4, 14, 15, 2, 22},
            {0, 23, 5, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        expected = 1,
        target = {x = 2, y = 2}
    },
    {
        state = {
            {4, 14, 15, 2, 22},
            {0, 23, 5, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        expected = 7,
        target = {x = 5, y = 5}
    },
    {
        state = {
            {4, 14, 15, 2, 22},
            {0, 23, 5, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        expected = 5,
        target = {x = 5, y = 1}
    },
    {
        state = {
            {4, 14, 15, 2, 22},
            {0, 23, 5, 11, 7},
            {20, 3, 12, 6, 17},
            {18, 19, 24, 8, 16},
            {13, 10, 1, 9, 21}
        },
        expected = 0,
        target = {x = 1, y = 2}
    },
}

for index, testData in pairs(blankManhattanTest) do
    print("TEST BLANK MANHATTAN ")
    local puzzle = Puzzle:new(5, testData.state)
    print("State:", puzzle:serialize())
    local h = puzzle:blankManhattan(testData.target.x, testData.target.y)
    assert(h == testData.expected, h .. " ~= " .. testData.expected)
    print("------------------ END -------------------------")
end

local start = {
    {   1,   2,   3,   6,  15 },
    {  12,   8,   0,  16,  13 },
    {  22,  24,  17,  19,  14 },
    {   9,   5,   7,  23,  20 },
    {  10,  18,  21,   4,  11 }
}
-- THIS ISN"T WORKING
local puzzle = Puzzle:new(5, start)
puzzle:generateWinningString()
puzzle:prettyPrint()
puzzle = solve(puzzle, puzzle:getPosition(4), puzzle:getGoals()[4], 4)
puzzle:prettyPrint()
