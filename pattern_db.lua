---
--- Created by nate.
--- DateTime: 6/21/24 10:15 PM
---
local Puzzle = require("Puzzle")

function generatePatternDb(group)
    print("Generating for group")
    prettyPrint(group)
    local iterations = 0
   -- Solve group 1
   local puzzle = Puzzle:new(4)
   puzzle:generateWinningString()
   stack = {}
   table.insert(stack, { puzzle = puzzle:clone(), g = 0 })
   local states = {}

    local function searchBruceForce(path, closedPaths, g)
       -- recursively move through state
        while #stack > 0 do
            local newMoves = {}
            path = table.remove(stack)
            path = path.puzzle
            iterations = iterations + 1
            if (iterations % 100000 == 0) then
                print("visited: " .. tablelength(closedPaths) .. " stored: " .. tablelength(states) .. " " .. " g: " .. path.count .. " : stack: " .. #stack)
            end
            -- Find all valid moves that have not been explored in the past
            if path:getPosition(0).x > 1 then
                local validMove, newMove = path:simulateMove(LEFT)
                if validMove == true and closedPaths[newMove:serializeGroup(group, false)] == nil then
                    table.insert(newMoves, { puzzle = newMove, parent = states[path:serialize()], position = newMove:getPosition(0), g = g, direction = "LEFT"})
                end
            end
            if path:getPosition(0).x < path:getBoardSize() then
                local validMove, newMove = path:simulateMove(RIGHT)
                if validMove == true and closedPaths[newMove:serializeGroup(group, false)] == nil then
                    table.insert(newMoves, { puzzle = newMove, parent = states[path:serialize()], position = newMove:getPosition(0), g = g, direction = "RIGHT"})
                end
            end
            if path:getPosition(0).y > 1 then
                local validMove, newMove = path:simulateMove(UP)
                if validMove == true and closedPaths[newMove:serializeGroup(group, false)] == nil then
                    table.insert(newMoves, { puzzle = newMove, parent = states[path:serialize()], position = newMove:getPosition(0), g = g, direction = "UP"})
                end
            end
            if path:getPosition(0).y < path:getBoardSize() then
                local validMove, newMove = path:simulateMove(DOWN)
                if validMove == true and closedPaths[newMove:serializeGroup(group, false)] == nil then
                    table.insert(newMoves, { puzzle = newMove, parent = states[path:serialize()], position = newMove:getPosition(0), g = g, direction = "DOWN"})
                end
            end

            -- For all new moves found, set a key on the table with the serialized puzzle value so we can easily find it in the future
            -- Add the valid newMoves to the overall list of paths to sort at the end.
            -- Call this function again on all valid states found
            for i = 1, #newMoves do
                closedPaths[newMoves[i].puzzle:serializeGroup(group, false)] = "OCCUPIED"
                states[newMoves[i].puzzle:serializeGroup(group)] = newMoves[i].puzzle.count
                table.insert(stack, { puzzle = newMoves[i].puzzle})
            end
        end
        return states
    end

    local closedPaths = {}
    local startingG = 0
    closedPaths[puzzle:serialize()] = "OCCUPIED"
    return searchBruceForce(puzzle:clone(), closedPaths, startingG)
end
