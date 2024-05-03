local Puzzle = require("Puzzle")

local stateA = {
    {7, 10, 1, 14},
    {6, 2, 9, 5},
    {3, 11, 0, 4},
    {8, 12, 13, 15}
}

local puzzle = Puzzle:new(3, stateA)
puzzle:generateWinningString()
print("State:", puzzle:serialize())
local h = puzzle:getHeuristic()
print(h)
assert(h == 42, "Error getting heuristic")
print("--------------END-------------------")
