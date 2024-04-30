local BLANK_SPACE_VALUE = 0
local PUZZLE_WIDTH = 4
local Moves = {}

local currentState = {
    {2, 222, 15, 55, 1},
    {9, 19, 21, 17, 3},
    {8, 6, 10, 24, 23},
    {11, 12, 7, 4, 0},
    {5, 20, 22, 14, 16},
}

local desiredState = {
    {1, 2, 3, 4, 5},
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

function FindValueInState(state, value)
    for row, rowData in pairs(state) do
        for col, colData in pairs(rowData) do
            if (colData == value) then
                return {row = row, col = col}
            end
        end
    end
end

local function moveBlankRight(state, blankPosition)
    print("RIGHT")
    blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    state[blankPosition.row][blankPosition.col] = state[blankPosition.row][blankPosition.col + 1]
    state[blankPosition.row][blankPosition.col + 1] = BLANK_SPACE_VALUE
    blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    prettyPrint(state)
    return blankPosition
end

local function moveBlankLeft(state, blankPosition)
    print("LEFT")
    blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    state[blankPosition.row][blankPosition.col] = state[blankPosition.row][blankPosition.col - 1]
    state[blankPosition.row][blankPosition.col - 1] = BLANK_SPACE_VALUE
    blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    prettyPrint(state)
    return blankPosition
end

local function moveBlankUp(state, blankPosition)
    print("UP")
    blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    state[blankPosition.row][blankPosition.col] = state[blankPosition.row - 1][blankPosition.col]
    state[blankPosition.row - 1][blankPosition.col] = BLANK_SPACE_VALUE
    blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    prettyPrint(state)
    return blankPosition
end

local function moveBlankDown(state, blankPosition)
    print("DOWN")
    blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    state[blankPosition.row][blankPosition.col] = state[blankPosition.row + 1][blankPosition.col]
    state[blankPosition.row + 1][blankPosition.col] = BLANK_SPACE_VALUE
    blankPosition = FindValueInState(state, BLANK_SPACE_VALUE)
    prettyPrint(state)
    return blankPosition
end

local function moveBlankRelativeToPosition(targetValue, relativePositionXY)
    local valuePosition = FindValueInState(currentState, targetValue)
    local targetPosition = {col = valuePosition.col + relativePositionXY.col, row = valuePosition.row + relativePositionXY.row}
    print("Target position is col: ", targetPosition.col, " row: ", targetPosition.row)
end

function MoveTileToDesiredPosition(targetValue, currentState, desiredState)
    local desiredPositon = FindValueInState(desiredState, targetValue)
    local currentPositon = FindValueInState(currentState, targetValue)
    local blankPosition = FindValueInState(currentState, BLANK_SPACE_VALUE)

    if (blankPosition.row == 1) then
        blankPosition = moveBlankDown(currentState, blankPosition)
        blankPosition = moveBlankDown(currentState, blankPosition)
    end
    currentPositon = FindValueInState(currentState, targetValue)


    prettyPrint(currentState)

    if (desiredPositon.col == currentPositon.col and desiredPositon.row == currentPositon.row) then
        print("No movement needed. Target tile ", targetValue, " is in position")
        return "No movement needed"
    end

    -- Do we need to move left or right
    local needsToMoveLeft = false
    if (desiredPositon.col < currentPositon.col) then
        needsToMoveLeft = true
    end
    
    local needsToMoveDown = false
    if (desiredPositon.row > currentPositon.row) then
        needsToMoveDown = true
    end

    -- If the target needs to move left, we want to place the blank space to the left before we move
    local targetBlankStartingPositon = {}
    if (needsToMoveLeft == true) then
        targetBlankStartingPositon = {col = currentPositon.col - 1, row = currentPositon.row}
    else
        targetBlankStartingPositon = {col = currentPositon.col + 1, row = currentPositon.row}
    end

    -- Is the blank space to the left or to the right
    local isBlankToTheLeft = false
    if (blankPosition.col < targetBlankStartingPositon.col) then
        isBlankToTheLeft = true
    end

    -- Is the blank space above or below
    local isBlankAbove = false
    if (blankPosition.row < targetBlankStartingPositon.row) then
        isBlankAbove = true
    end

    -- We need to move left

    -- If we are in the same row as the target and we need to move past it, then we should move down one first
    -- Do the movement col
    local verticalAdjustment = false
    if (blankPosition.row == currentPositon.row and ((not isBlankToTheLeft and needsToMoveLeft) or (isBlankToTheLeft and not needsToMoveLeft))) then
        verticalAdjustment = true
    end

    if (verticalAdjustment == true) then
        print(blankPosition.row)
        if (blankPosition.row == 5) then
            blankPosition = moveBlankUp(currentState, blankPosition)
        else 
            blankPosition = moveBlankDown(currentState, blankPosition)
        end
    end
    if (blankPosition.col ~= currentPositon.col) then
        if (needsToMoveLeft == true) then
            for i = 0, math.abs(blankPosition.col - currentPositon.col), 1 do
                blankPosition = moveBlankLeft(currentState, blankPosition)
            end
        else
            for i = 1, math.abs(blankPosition.col - currentPositon.col - 1), 1 do
                blankPosition = moveBlankLeft(currentState, blankPosition)
            end
        end
    end
    if (verticalAdjustment == true) then
        if (blankPosition.row == 4) then
            blankPosition = moveBlankDown(currentState, blankPosition)
        else
            blankPosition = moveBlankUp(currentState, blankPosition)
        end
    end

    -- If we are in the same row as the target and we need to move past it, then we should move down one first
    -- Do the movement row
    local horizontalAdjustment = false
    if (blankPosition.col == currentPositon.col and ((isBlankAbove and needsToMoveDown) or (not isBlankAbove and not needsToMoveDown))) then
        horizontalAdjustment = true
    end

    if (horizontalAdjustment == true) then
        if (blankPosition.col == 5) then
            blankPosition = moveBlankLeft(currentState, blankPosition)
        else 
            blankPosition = moveBlankRight(currentState, blankPosition)
        end
    end
    if (blankPosition.row ~= currentPositon.row) then
        if (needsToMoveDown == true) then
            for i = 0, math.abs(blankPosition.row - currentPositon.row), 1 do
                blankPosition = moveBlankUp(currentState, blankPosition)
            end
        else
            for i = 1, math.abs(blankPosition.row - currentPositon.row), 1 do
                blankPosition = moveBlankDown(currentState, blankPosition)
            end
        end
    end
    if (horizontalAdjustment == true) then
        if (blankPosition.col == 4) then
            blankPosition = moveBlankRight(currentState, blankPosition)
        else
            blankPosition = moveBlankLeft(currentState, blankPosition)
        end
    end

    return currentState
end

local function calculateMoveSetToSolveTopRow()
    -- solve 1
    local solve_target = 1
    -- move the blank space adjacent to the block we want to move. It should be to the direction of whichever way to want to move it.
    -- for example, if we want to move the tile "1" to the left, then we need to place the blank on the left of it.
    -- rules when getting blank into position:
    -- 1. Do not pass existing 'locked' positions. Will need a temporarily exception for the final position in a row/column
    -- 2. Do not pass through the tile you are trying to move
    -- example:
    -- Is there space above?
    -- If yes, calculate the possible path and check if it runs into locked spaces
    -- If it does, try moving the opposite direction (if above, then below)
        print("Solving...")
        prettyPrint(currentState)
    -- solve 1
    moveTileToDesiredPosition(1, currentState, desiredState)
    -- moveTileToDesiredPosition(2, 0, 0)
    -- moveTileToDesiredPosition(3, 0, 0)
    -- moveTileToDesiredPosition(4, 1, 0)
    -- moveTileToDesiredPosition(5, 1, 0)



    -- while (FindValueInState(currentState, solve_target).col ~= FindValueInState(desiredState, solve_target).col) do
    --     local onePosition = FindValueInState(currentState, solve_target)
    --     local desiredOnePosition = FindValueInState(desiredState, solve_target)

    --     local diffX = (desiredOnePosition.col - onePosition.col)
    --     local diffY = (desiredOnePosition.row - onePosition.row)

    --     print(solve_target, " needs to move x: ", diffX, " y: ", diffY)
    --     print("Calulating move set for row")
    --     if (diffX == 0) then
    --         print("No moves needed for x")
    --     else
    --         moveX(diffX, onePosition, currentState)
    --     end
    -- end

    -- -- for i = 1, 2 do
    -- while (FindValueInState(currentState, solve_target).row ~= FindValueInState(desiredState, solve_target).row) do
    --     local onePosition = FindValueInState(currentState, solve_target)
    --     local desiredOnePosition = FindValueInState(desiredState, solve_target)

    --     local diffX = (desiredOnePosition.col - onePosition.col)
    --     local diffY = (desiredOnePosition.row - onePosition.row)

    --     print(solve_target, " needs to move x: ", diffX, " y: ", diffY)
    --     print("Calulating move set for row")
    --     if (diffY == 0) then
    --         print("No moves needed for y")
    --     else
    --         moveY(diffY, onePosition, currentState)
    --     end
    -- end
    -- print("DONE WITH ONE")
end

-- calculateMoveSetToSolveTopRow()
-- for index, move in ipairs(MOVES) do
--     print(move.direction)
-- end