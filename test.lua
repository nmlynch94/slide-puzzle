
local BLANK_SPACE_VALUE = "00"
local PUZZLE_WIDTH = 4
local Moves = {}

local currentState = {
    {"14", "21", "23", "03", "11"},
    {"10", "15", "16", "20", "08"},
    {"18", "05", "22", "06", "01"},
    {"07", "19", "12", "17", "02"},
    {"09", "24", "04", "13", "00"},
}

local desiredState = {
    {"01", "02", "03", "04", "05"},
    {"06", "07", "08", "09", "10"},
    {"11", "12", "13", "14", "15"},
    {"16", "17", "18", "19", "20"},
    {"21", "22", "23", "24", "00"},
}

local currentState3by3 = {
    {"07", "03", "04"},
    {"08", "06", "02"},
    {"01", "05", "00"}
}

local desiredState3by3 = {
    {"01", "02", "03"},
    {"04", "05", "06"},
    {"07", "08", "00"}
}

local currentState4by4 = {

}

local desiredState4by4 = {

}

local desiredState2 = {
    {1, 2, 3, 4, 56},
    {6, 7, 8, 9, 10},
    {11, 12, 13, 14, 15},
    {16, 17, 18, 19, 20},
    {21, 22, 23, 24, 0},
}


local currentTargetPosition

local function deepCopy(original)
    local original_type = type(original)
    local copy
    if original_type == 'table' then
        copy = {}
        for original_key, original_value in next, original, nil do
            copy[deepCopy(original_key)] = deepCopy(original_value)
        end
        setmetatable(copy, deepCopy(getmetatable(original)))
    else -- number, string, boolean, etc
        copy = original
    end
    return copy
end

function prettyPrint(array)
    for i, row in ipairs(array) do
        for j, value in ipairs(row) do
            io.write(string.format("%4d", value))
            if j < #row then
                io.write(", ")
            end
        end
        io.write("\n")
    end
    print("------------")
end

function prettyPrintPosition(position)
    print("row: ", position.row, " col: ", position.col)
end

function FindValueInState(state, value)
    for row, rowData in pairs(state) do
        for col, colData in pairs(rowData) do
            if (colData == value) then
                return {row = row, col = col}
            end
        end
    end
end

local function moveBlankRight(state)
    print("RIGHT")
    local blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    state[blankPosition.row][blankPosition.col] = state[blankPosition.row][blankPosition.col + 1]
    state[blankPosition.row][blankPosition.col + 1] = BLANK_SPACE_VALUE
    blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    prettyPrint(state)
    return blankPosition
end

local function moveBlankLeft(state)
    print("LEFT")
    local blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    state[blankPosition.row][blankPosition.col] = state[blankPosition.row][blankPosition.col - 1]
    state[blankPosition.row][blankPosition.col - 1] = BLANK_SPACE_VALUE
    blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    prettyPrint(state)
    return blankPosition
end

local function moveBlankUp(state)
    print("UP")
    local blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    state[blankPosition.row][blankPosition.col] = state[blankPosition.row - 1][blankPosition.col]
    state[blankPosition.row - 1][blankPosition.col] = BLANK_SPACE_VALUE
    blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    prettyPrint(state)
end

local function moveBlankDown(state)
    print("DOWN")
    local blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    state[blankPosition.row][blankPosition.col] = state[blankPosition.row + 1][blankPosition.col]
    state[blankPosition.row + 1][blankPosition.col] = BLANK_SPACE_VALUE
    blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    prettyPrint(state)
end

function doStatesMatch(stateA, stateB, rowLimiter)
    if rowLimiter ~= nil then
        for i = 1, rowLimiter do
            for col, colData in pairs(stateA[i]) do
                if (colData ~= stateB[i][col]) then
                    return false
                end
            end
        end
        return true
    end

    for row, rowData in pairs(stateA) do
        for col, colData in pairs(rowData) do
            if (colData ~= stateB[row][col]) then
                return false
            end
        end
    end
    return true
end

local function calculateManhattanDistance(currentState, goalState)
    local distance = 0
    local goalPos = {}

    -- First, map each tile to its goal position from the goalState
    for row = 1, #goalState do
        for col = 1, #goalState[row] do
            goalPos[goalState[row][col]] = {row = row, col = col}
        end
    end

    -- Now, calculate the Manhattan Distance for each tile in the currentState
    for row = 1, #currentState do
        for col = 1, #currentState[row] do
            local tile = currentState[row][col]
            if tile ~= "00" then -- Ignore the blank space
                local goalRow = goalPos[tile].row
                local goalCol = goalPos[tile].col
                distance = distance + math.abs(row - goalRow) + math.abs(col - goalCol)
            end
        end
    end

    return distance
end


local statePairs = {}
local counter = 0
local currentStateToSolve = currentState3by3
local currentDesiredState = desiredState3by3

local lockedStates = {}

function isLocked(state, threshhold)
    for index, lockedState in pairs(lockedStates) do
        if doStatesMatch(state, lockedState, nil) and calculateManhattanDistance(state, currentDesiredState) <= threshhold then
            print("STATE IS LOCKED")
            prettyPrint(state)
            prettyPrint(lockedState)
            return true
        end
    end
    return false
end

local threshhold = calculateManhattanDistance(currentStateToSolve, currentDesiredState)
function doIt(state)

    print("TOTAL PERMUTATIONS: ", #statePairs)
    print("LOCKED STATES: ", #lockedStates)
    print("Heuristic: ", calculateManhattanDistance(state, currentDesiredState))
    local newStates = {}
    local blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)

    if doStatesMatch(state, currentDesiredState, nil) then
        print("MATCH")
        prettyPrint(state)
        error("MAAAAATCH")
    end

    if blankPosition.row < #state then
        local downState = deepCopy(state)
        moveBlankDown(downState)
        if not isLocked(downState, threshhold) then
            table.insert(newStates, {parent = state ,state = downState, heuristic = calculateManhattanDistance(downState, currentDesiredState), direction = "DOWN"})
        end
    end

    if blankPosition.row > 1 then
        local upState = deepCopy(state)
        moveBlankUp(upState)
        if not isLocked(upState, threshhold) then
            table.insert(newStates, {parent = state, state = upState, heuristic = calculateManhattanDistance(upState, currentDesiredState), direction = "UP"})
        end
    end

    if blankPosition.col > 1 then
        local leftState = deepCopy(state)
        moveBlankLeft(leftState)
        if not isLocked(leftState, threshhold) then
            table.insert(newStates, {parent = state, state = leftState, heuristic = calculateManhattanDistance(leftState, currentDesiredState), direction = "LEFT"})
        end
    end

    if blankPosition.col < #state then
        local rightState = deepCopy(state)
        moveBlankRight(rightState)
        if not isLocked(rightState, threshhold) then
            table.insert(newStates, {parent = state, state = rightState, heuristic = calculateManhattanDistance(rightState, currentDesiredState), direction = "RIGHT"})
        end
    end

    local unlockedStatesUnderThreshhold = 0

    table.sort(newStates, function(a, b)
        return a.heuristic < b.heuristic
    end)
    
    for index, state in pairs(newStates) do
        print(state.heuristic)
    end

    if #newStates == 0 then
        print("Out of states for this round")
        return
    end

    -- Raise threshhold if the lowest isn't under the current one
    if newStates[1].heuristic > threshhold then
        print("None found with heuristic ", threshhold, " raising to ", newStates[#newStates].heuristic)
        local newThreshhold = newStates[#newStates].heuristic
        
        -- Add back any locked states that are less than the new threshold, but above the old threshold
        for index, state in pairs(lockedStates) do
            local manhattan = calculateManhattanDistance(state, currentDesiredState)
            if (manhattan > threshhold and manhattan <= newThreshhold) then
                print("INSERTING LOCKED STATE: ", manhattan)
                table.insert(newStates, state)
                table.remove(lockedStates, index)
            end
        end
        threshhold = newStates[#newStates].heuristic

    end

    for index, state in pairs(newStates) do
        if state.heuristic <= threshhold then
            unlockedStatesUnderThreshhold = unlockedStatesUnderThreshhold + 1
            table.insert(statePairs, state)
            table.insert(lockedStates, state.state)
            doIt(state.state)
        end
    end
end

local state = deepCopy(currentStateToSolve)
table.insert(lockedStates, state)
-- for i = 1, 2 do
doIt(state)
-- end


local function formatArray(array)
    local lines = {}
    for i, row in ipairs(array) do
        local formattedRow = {}
        for j, value in ipairs(row) do
            -- Formatting the number to two digits, note 222 will remain as 222
            table.insert(formattedRow, string.format("%02d", value))
        end
        -- Concatenating formatted numbers with commas and adding braces
        table.insert(lines, "{" .. table.concat(formattedRow, ", ") .. "}")
    end
    -- Joining all rows with newline
    return table.concat(lines, ",\\n")
end

local fileName = "output.txt"
local file = io.open(fileName, "a")
if file then
    for index, data in pairs(statePairs) do
        local formattedStateA = formatArray(data.parent)
        local formattedStateB = formatArray(data.state)
        file:write("\"", formattedStateA, "\" -> \"", formattedStateB, "\"", "\n")
    end
    file:close()
    print("Data has been written to " .. fileName)
else
    print("Failed to open the file.")
end