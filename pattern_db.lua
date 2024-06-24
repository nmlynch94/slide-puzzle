---
--- Created by nate.
--- DateTime: 6/21/24 10:15 PM
---
local Puzzle = require("Puzzle")

function writeToFile(filename, data)
    local file = io.open(filename, "w")
    if not file then
        error("Could not open file for writing: " .. filename)
    end

    for key, value in pairs(data) do
        file:write(key .. "=" .. value .. "\n")
    end

    file:close()
end

function readFromFile(filename)
    local file = io.open(filename, "r")
    if not file then
        error("Could not open file for reading: " .. filename)
    end

    local table = {}
    for line in file:lines() do
        local key, value = line:match("([^=]+)=([^=]+)")
        if key and value then
            table[key] = tonumber(value) or value
        end
    end

    file:close()
    return table
end

function generatePatternDb(group, puzzleSize)
    local startTime = os.time()
    print("Generating for group")
    print(table.concat(group, ", "))
    local iterations = 0
   -- Solve group 1
   local puzzle = Puzzle:new(puzzleSize)
   puzzle:generateWinningString()
   stack = {}
   table.insert(stack, { puzzle = puzzle:clone(), g = 0 })
   local closedList = {}

    local function searchBruceForce(path, visited, g)
       -- recursively move through state
        while #stack > 0 do
            local newMoves = {}
            path = table.remove(stack, 1)
            path = path.puzzle
            local parentPathSerialized = path:serialize()
            iterations = iterations + 1
            if (iterations % 100000 == 0) then
                print("visitedNodes: " .. tablelength(visited) .. " storedStates: " .. tablelength(closedList) .. " " .. " : openNodes: " .. #stack .. " timeElapsed: " .. os.time() - startTime .. " seconds")
            end
            local previousBlankPosition = path:getPosition(0)
            -- Find all valid moves that have not been explored in the past
            if path:getPosition(0).x > 1 then
                local validMove, newMove = path:simulateMove(LEFT)
                if validMove == true and parentPathSerialized ~= path.parent then
                    table.insert(newMoves, { puzzle = newMove, parent = parentPathSerialized })
                end
            end
            if path:getPosition(0).x < path:getBoardSize() then
                local validMove, newMove = path:simulateMove(RIGHT)
                if validMove == true and parentPathSerialized ~= path.parent then
                    table.insert(newMoves, { puzzle = newMove, parent = parentPathSerialized })
                end
            end
            if path:getPosition(0).y > 1 then
                local validMove, newMove = path:simulateMove(UP)
                if validMove == true and parentPathSerialized ~= path.parent then
                    table.insert(newMoves, { puzzle = newMove, parent = parentPathSerialized })
                end
            end
            if path:getPosition(0).y < path:getBoardSize() then
                local validMove, newMove = path:simulateMove(DOWN)
                if validMove == true and parentPathSerialized ~= path.parent then
                    table.insert(newMoves, { puzzle = newMove, parent = parentPathSerialized })
                end
            end

            -- For all new moves found, set a key on the table with the serialized puzzle value so we can easily find it in the future
            -- Add the valid newMoves to the overall list of paths to sort at the end.
            -- Call this function again on all valid states found
            for i = 1, #newMoves do
                local curPuzzle = newMoves[i].puzzle
                local checkSumWithBlank = curPuzzle:serializeGroup(group, false)
                local checkSumWithoutBlank = curPuzzle:serializeGroup(group)
                if visited[checkSumWithBlank] ~= nil then
                    goto continue
                end
                -- If the move moved a tile that exists in the group, increment count
                local tileSwappedWithBlank = curPuzzle:getTile(previousBlankPosition.x, previousBlankPosition.y)
                if (has_value(tileSwappedWithBlank, group)) then
                    curPuzzle:increment()
                end

                local currentCount = newMoves[i].puzzle.count
                if closedList[checkSumWithoutBlank] == nil then
                    closedList[checkSumWithoutBlank] = currentCount
                elseif (closedList[checkSumWithoutBlank] > currentCount) then
                    closedList[checkSumWithoutBlank] = currentCount
                end
                if visited[checkSumWithBlank] == nil then
                    visited[checkSumWithBlank] = "OCCUPIED"
                    table.insert(stack, { puzzle = newMoves[i].puzzle})
                end
                ::continue::
            end
        end
        return closedList
    end

    local closedPaths = {}
    local startingG = 0
    closedPaths[puzzle:serialize()] = "OCCUPIED"
    return searchBruceForce(puzzle:clone(), closedPaths, startingG)
end
