local Puzzle = require("Puzzle")
local idastar = require("idastar")


-- local stateB = {
--     {4, 14, 15, 2, 22},
--     {0, 23, 5, 11, 7},
--     {20, 3, 12, 6, 17},
--     {18, 19, 24, 8, 16},
--     {13, 10, 1, 9, 21}
-- }

-- local moveTests = {
--     {
--         preMoveState = {
--             {4, 14, 15, 2, 22},
--             {0, 23, 5, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         postMoveState = {
--             {4, 14, 15, 2, 22},
--             {0, 23, 5, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         direction = LEFT
--     },
--     {
--         preMoveState = {
--             {4, 14, 15, 2, 22},
--             {5, 23, 0, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         postMoveState = {
--             {4, 14, 15, 2, 22},
--             {5, 0, 23, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         direction = LEFT
--     },
--     {
--         preMoveState = {
--             {4, 14, 15, 2, 22},
--             {0, 23, 5, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         postMoveState = {
--             {4, 14, 15, 2, 22},
--             {23, 0, 5, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         direction = RIGHT
--     },
--     {
--         preMoveState = {
--             {4, 14, 15, 2, 22},
--             {0, 23, 5, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         postMoveState = {
--             {0, 14, 15, 2, 22},
--             {4, 23, 5, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         direction = UP
--     },
--     {
--         preMoveState = {
--             {4, 14, 15, 2, 22},
--             {0, 23, 5, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         postMoveState = {
--             {4, 14, 15, 2, 22},
--             {20, 23, 5, 11, 7},
--             {0, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         direction = DOWN
--     },
-- }

-- -- for index, testData in pairs(moveTests) do
-- --     print("TEST MOVING " .. index .. " - " .. testData.direction.x .. ", " .. testData.direction.y)
-- --     local puzzle = Puzzle:new(5, testData.preMoveState)
-- --     puzzle:generateWinningString()
-- --     print("State:", puzzle:serialize())
-- --     puzzle:move(testData.direction)
-- --     local preMoveState = puzzle:serialize()
-- --     puzzle:prettyPrint()
-- --     print("---------------")
-- --     Puzzle:new(5, testData.postMoveState):prettyPrint()
-- --     local postMoveState = Puzzle:new(5, testData.postMoveState):serialize()
-- --     assert(preMoveState == postMoveState, preMoveState .. " ~= " .. postMoveState)
-- --     print("------------------ END -------------------------")
-- -- end

-- local blankManhattanTest = {
--     {
--         state = {
--             {4, 14, 15, 2, 22},
--             {0, 23, 5, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         expected = 1,
--         target = {x = 2, y = 2}
--     },
--     {
--         state = {
--             {4, 14, 15, 2, 22},
--             {0, 23, 5, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         expected = 7,
--         target = {x = 5, y = 5}
--     },
--     {
--         state = {
--             {4, 14, 15, 2, 22},
--             {0, 23, 5, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         expected = 5,
--         target = {x = 5, y = 1}
--     },
--     {
--         state = {
--             {4, 14, 15, 2, 22},
--             {0, 23, 5, 11, 7},
--             {20, 3, 12, 6, 17},
--             {18, 19, 24, 8, 16},
--             {13, 10, 1, 9, 21}
--         },
--         expected = 0,
--         target = {x = 1, y = 2}
--     },
-- }

-- -- for index, testData in pairs(blankManhattanTest) do
-- --     print("TEST BLANK MANHATTAN ")
-- --     local puzzle = Puzzle:new(5, testData.state)
-- --     print("State:", puzzle:serialize())
-- --     local h = puzzle:blankManhattan(testData.target.x, testData.target.y)
-- --     assert(h == testData.expected, h .. " ~= " .. testData.expected)
-- --     print("------------------ END -------------------------")
-- -- end


-- local start = {
--     {   1,   2,   3,   6,  15 },
--     {  12,   8,   0,  16,  13 },
--     {  22,  24,  17,  19,  14 },
--     {   9,   5,   7,  23,  20 },
--     {  10,  18,  21,   4,  11 }
-- }
-- local expectedState = {
--     {   1,   2,   3,   4,   6 },
--     {  12,   8,  17,   0,  15 },
--     {  22,  24,  19,  13,  16 },
--     {   9,   5,   7,  14,  23 },
--     {  10,  18,  21,  11,  20 },
-- }
-- print("TEST DOING IT")
-- -- THIS ISN"T WORKING
-- local puzzle = Puzzle:new(5, start)
-- puzzle:generateWinningString()
-- puzzle:prettyPrint()
-- direction, _ = pathBlankToPosition(puzzle, {x = 4, y = 4})
-- prettyPrint(direction)
-- _:prettyPrint()
-- moveAlgorithm(_, UP, 4)
-- assert(_:serialize(), Puzzle:new(5, expectedState):serialize())

-- local start = {
--     {   1,   2,   3,   6,  15 },
--     {  12,   8,   0,  16,  13 },
--     {  22,  24,  17,  19,  14 },
--     {   9,   5,   7,  23,  20 },
--     {  10,  18,  21,   4,  11 }
-- }
-- local expectedState = {
--     {   1,   2,   3,   4,   6 },
--     {  12,   8,  17,   0,  15 },
--     {  22,  24,  19,  13,  16 },
--     {   9,   5,   7,  14,  23 },
--     {  10,  18,  21,  11,  20 },
-- }
-- print("TEST DOING IT")
-- -- THIS ISN"T WORKING
-- local puzzle = Puzzle:new(5, start)
-- puzzle:generateWinningString()
-- puzzle:prettyPrint()
-- puzzle:lockPosition(3, 5)
-- direction, _ = pathBlankToPosition(puzzle, {x = 2, y = 5})
-- _:unlockLatest()
-- _:prettyPrint()
-- print("STARTING MOVEMENT")
-- moveAlgorithm(_, LEFT, 2)
-- assert(_:serialize(), Puzzle:new(5, expectedState):serialize())

-- local start = {
--     {   1,   2,   3,   6,  15 },
--     {  12,   8,   0,  16,  13 },
--     {  22,  24,  17,  19,  11 },
--     {   9,   5,   7,  23,  20 },
--     {  10,  18,  21,   4,  14 }
-- }
-- local expectedState = {
--     {   1,   2,   3,   4,   6 },
--     {  12,   8,  17,   0,  15 },
--     {  22,  24,  19,  13,  16 },
--     {   9,   5,   7,  14,  23 },
--     {  10,  18,  21,  11,  20 },
-- }
-- print("TEST DOING IT")
-- -- THIS ISN"T WORKING
-- local puzzle = Puzzle:new(5, start)
-- puzzle:generateWinningString()
-- puzzle:prettyPrint()
-- puzzle:lockPosition(3, 5)
-- direction, _ = pathBlankToPosition(puzzle, {x = 2, y = 5})
-- _:unlockLatest()
-- _:prettyPrint()
-- print("STARTING MOVEMENT")
-- moveAlgorithm(_, LEFT, 2)
-- assert(_:serialize(), Puzzle:new(5, expectedState):serialize())


local start = {
    {   1,   2,   3,   4,   5 },
    {   6,   0,  11,  21,  10 },
    {   9,  16,  22,   7,  19 },
    {  17,  20,   8,  12,  23 },
    {  18,  13,  14,  24,  15 },
}

for i = 1, 100 do
    local puzzle = Puzzle:new(5, start)
    puzzle:shuffle()
    puzzle:generateWinningString()
    puzzle = solve(puzzle, puzzle:getPosition(11), puzzle:getGoals()[11], 11)
    assert() 
end
