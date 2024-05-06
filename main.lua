require('util')
local argparse = require("argparse")
local parser = argparse("lua main.lua", "Solves 5x5 slide puzzles")
local Puzzle = require("Puzzle")

local state_option = parser:option("-i --state", "A string representation of the puzzle state delimited by '-'. Example 5x5 '11-7-2-24-6-8-12-9-5-20-4-14-3-18-22-1-21-0-13-23-16-17-19-10-15'.")
    :count(1)

local args = parser:parse()

local state = split(args.state, "-")

if not (#state == 25 or #state == 16 or #state == 9) then
    print("Input state is " .. #state)
    parser:error("Only 5x5 (25), 4x4 (16), and 3x3 (9) puzzles are supported")
end

-- convert string into 2d puzzle
local initialState = {}
local size = math.sqrt(#state)
for i = 1, size do
    table.insert(initialState, {})
    for j = 1, size do
        initialState[i][j] = tonumber(math.floor(state[(i - 1) * size + j]))
    end
end

local directions = Puzzle:new(size, initialState)
    :generateWinningString()
    :solve()

-- make sure the directions are valid
local solvedPuzzle = Puzzle:new(size, initialState)
    :generateWinningString()
    :playDirections(directions)

local serializedString = Puzzle:new(size, initialState):serialize()

print("starting state: " ..  args.state .. " : " .. serializedString)
assert(solvedPuzzle:getWinningString() == solvedPuzzle:serialize(), solvedPuzzle:getWinningString() .. " ".. solvedPuzzle:serialize())
print("moves: " .. #directions)
printDirectionsTenPerLine(directions)