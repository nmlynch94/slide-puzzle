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
   local puzzle = Puzzle:new(3)
   puzzle:generateWinningString()
   stack = {}
   table.insert(stack, { puzzle = puzzle:clone(), g = 0 })
   local closedList = {}

    local function searchBruceForce(path, visited, g)
       -- recursively move through state
        while #stack > 0 do
            local newMoves = {}
            path = table.remove(stack)
            path = path.puzzle
            iterations = iterations + 1
            if (iterations % 100000 == 0) then
                print("visited: " .. tablelength(visited) .. " states: " .. tablelength(closedList) .. " " .. " g: " .. path.count .. " : open: " .. #stack .. " total: " .. math.floor(16 * 16))
            end
            local previousBlankPosition = path:getPosition(0)
            -- Find all valid moves that have not been explored in the past
            if path:getPosition(0).x > 1 then
                local validMove, newMove = path:simulateMove(LEFT)
                if validMove == true and visited[newMove:serializeGroup(group, false)] == nil then
                    table.insert(newMoves, { puzzle = newMove, parent = closedList[path:serialize()], position = newMove:getPosition(0), g = g, direction = "LEFT"})
                end
            end
            if path:getPosition(0).x < path:getBoardSize() then
                local validMove, newMove = path:simulateMove(RIGHT)
                if validMove == true and visited[newMove:serializeGroup(group, false)] == nil then
                    table.insert(newMoves, { puzzle = newMove, parent = closedList[path:serialize()], position = newMove:getPosition(0), g = g, direction = "RIGHT"})
                end
            end
            if path:getPosition(0).y > 1 then
                local validMove, newMove = path:simulateMove(UP)
                if validMove == true and visited[newMove:serializeGroup(group, false)] == nil then
                    table.insert(newMoves, { puzzle = newMove, parent = closedList[path:serialize()], position = newMove:getPosition(0), g = g, direction = "UP"})
                end
            end
            if path:getPosition(0).y < path:getBoardSize() then
                local validMove, newMove = path:simulateMove(DOWN)
                if validMove == true and visited[newMove:serializeGroup(group, false)] == nil then
                    table.insert(newMoves, { puzzle = newMove, parent = closedList[path:serialize()], position = newMove:getPosition(0), g = g, direction = "DOWN"})
                end
            end

            -- For all new moves found, set a key on the table with the serialized puzzle value so we can easily find it in the future
            -- Add the valid newMoves to the overall list of paths to sort at the end.
            -- Call this function again on all valid states found
            for i = 1, #newMoves do
                print(newMoves[i].puzzle:serializeGroup(group), newMoves[i].puzzle.count)
                -- If the move moved a tile that exists in the group, increment count
                local tileSwappedWithBlank = newMoves[i].puzzle:getTile(previousBlankPosition.x, previousBlankPosition.y)
                if (has_value(tileSwappedWithBlank, group)) then
                    print(newMoves[i].puzzle:serializeGroup(group) .. " --> " .. newMoves[i].puzzle.count)
                    newMoves[i].puzzle:increment()
                end
                local groupHash = newMoves[i].puzzle:serializeGroup(group)

                local currentCount = newMoves[i].puzzle.count
                if closedList[groupHash] == nil then
                    closedList[groupHash] = currentCount
                elseif (closedList[groupHash] > currentCount) then
                    closedList[groupHash] = currentCount
                end
                visited[newMoves[i].puzzle:serializeGroup(group, false)] = "OCCUPIED"
                table.insert(stack, { puzzle = newMoves[i].puzzle})
            end
            ::continue_while::
        end
        return closedList
    end

    local closedPaths = {}
    local startingG = 0
    closedPaths[puzzle:serialize()] = "OCCUPIED"
    return searchBruceForce(puzzle:clone(), closedPaths, startingG)
end
