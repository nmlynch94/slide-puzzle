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

local function prettyPrint(array)
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

local blankPosition = FindValueInState(currentState, 0)
MOVES = {}
UNCOMMITTEDMOVES = {}
LockedPositions = {}

local function moveBlankRight()
    print("RIGHT")
    blankPosition = FindValueInState(currentState, BLANK_SPACE_VALUE)
    table.insert(UNCOMMITTEDMOVES, {direction = "RIGHT", position = {col = blankPosition.col + 1, row = blankPosition.row}})
    currentState[blankPosition.row][blankPosition.col] = currentState[blankPosition.row][blankPosition.col + 1]
    currentState[blankPosition.row][blankPosition.col + 1] = BLANK_SPACE_VALUE
    blankPosition = FindValueInState(currentState, BLANK_SPACE_VALUE)
    prettyPrint(currentState)
end

local function moveBlankLeft()
    print("LEFT")
    blankPosition = FindValueInState(currentState, BLANK_SPACE_VALUE)
    table.insert(UNCOMMITTEDMOVES, {direction = "LEFT", position = {col = blankPosition.col - 1, row = blankPosition.row}})
    currentState[blankPosition.row][blankPosition.col] = currentState[blankPosition.row][blankPosition.col - 1]
    currentState[blankPosition.row][blankPosition.col - 1] = BLANK_SPACE_VALUE
    blankPosition = FindValueInState(currentState, BLANK_SPACE_VALUE)
    prettyPrint(currentState)
end

local function moveBlankUp()
    print("UP")
    blankPosition = FindValueInState(currentState, BLANK_SPACE_VALUE)
    table.insert(UNCOMMITTEDMOVES, {direction = "UP", position = {col = blankPosition.col, row = blankPosition.row - 1}})
    currentState[blankPosition.row][blankPosition.col] = currentState[blankPosition.row - 1][blankPosition.col]
    currentState[blankPosition.row - 1][blankPosition.col] = BLANK_SPACE_VALUE
    blankPosition = FindValueInState(currentState, BLANK_SPACE_VALUE)
    prettyPrint(currentState)
end

local function moveBlankDown()
    print("DOWN")
    blankPosition = FindValueInState(currentState, BLANK_SPACE_VALUE)
    table.insert(UNCOMMITTEDMOVES, {direction = "DOWN", position = {col = blankPosition.col, row = blankPosition.row + 1}})
    currentState[blankPosition.row][blankPosition.col] = currentState[blankPosition.row + 1][blankPosition.col]
    currentState[blankPosition.row + 1][blankPosition.col] = BLANK_SPACE_VALUE
    blankPosition = FindValueInState(currentState, BLANK_SPACE_VALUE)
    prettyPrint(currentState)
end

-- assumes the blank is one in the direction that needs to be moved in
local function moveInDirectionAlgorithm(direction)

    local spaceAbove = blankPosition.row - 1 >= 0
    local spaceBelow = blankPosition.row + 1 < #desiredState
    local spaceRight = blankPosition.col + 1 < #desiredState
    local spaceLeft = blankPosition.col - 1 >= 0
    
    if (direction == "LEFT") then
        if (spaceBelow == true) then
            
        end
    end

end

--
local function moveX(spaces, position, state)
    -- move blank space to the side of the "1". Left if we want to move left, or right if we want to move right
    local desiredBlankPosition
    if (spaces > 0) then
        desiredBlankPosition = {col = position.col + 1, row = position.row}
    else
        desiredBlankPosition = {col = position.col - 1, row = position.row}
    end

    local diffX = (desiredBlankPosition.col - blankPosition.col)
    local diffY = (desiredBlankPosition.row - blankPosition.row)

    print("blank is at: ", blankPosition.row, ", ", blankPosition.col)
    print("we want it at: ", desiredBlankPosition.row, ", ", desiredBlankPosition.col)
    while (blankPosition.col ~= desiredBlankPosition.col) do
        if (diffX > 0) then
            moveBlankRight()
        elseif (diffX < 0) then
            moveBlankLeft()
        end
    end

    while (blankPosition.row ~= desiredBlankPosition.row) do
        if (diffY > 0) then
            moveBlankDown()
        elseif (diffY < 0) then
            moveBlankUp()
        end
    end

    if (spaces == 1) then
        -- move x one position to get the 1 into the right location
        moveBlankLeft()
    elseif (spaces == -1) then
        moveBlankRight()
    elseif (spaces < 0) then
        moveInDirectionAlgorithm("LEFT")
    elseif (spaces > 0) then
        moveInDirectionAlgorithm("RIGHT")
    end
end

local function moveY(spaces, position, state)
    print("BEGIN MOVE Y")
    -- move blank space above the "1"
    local desiredBlankPosition
    desiredBlankPosition = {col = position.col + 1, row = position.row}
 
    local diffX = (desiredBlankPosition.col - blankPosition.col)
    local diffY = (desiredBlankPosition.row - blankPosition.row)

    print("blank is at: ", blankPosition.row, ", ", blankPosition.col)
    print("we want it at: ", desiredBlankPosition.row, ", ", desiredBlankPosition.col)

    print(diffY)
    while (blankPosition.row ~= desiredBlankPosition.row) do
        if (diffY > 0) then
            moveBlankDown()
        elseif (diffY < 0) then
            moveBlankUp()
        end
    end

    while (blankPosition.col ~= desiredBlankPosition.col) do
        if (diffX > 0) then
            moveBlankRight()
        elseif (diffX < 0) then
            moveBlankLeft()
        end
    end

    if (spaces == 1) then
        -- move x one position to get the 1 into the right location
        moveBlankUp()
    elseif (spaces == -1) then
        moveBlankDown()
    elseif (spaces < 0) then
        moveInDirectionAlgorithm("UP")
    else
        moveInDirectionAlgorithm("DOWN")
    end
    print("END MOVE Y")
end

local function movesAreSafe(isMoveTargetValueSafetyEnabled, stateSnapshot, value)
    -- Loop through the array of tables
    local movesAreSafe = true
    for index, uncommittedMovePosition in ipairs(currentState) do
        if (#uncommittedMovePosition > #desiredState) then
            movesAreSafe = false
            break
        end
    end
    for index, uncommittedMovePosition in ipairs(UNCOMMITTEDMOVES) do
        if (uncommittedMovePosition.position.row == nil or uncommittedMovePosition.position.col == nil) then
            movesAreSafe = false
            break
        end
        for index, lockedPosition in ipairs(LockedPositions) do
            if (uncommittedMovePosition.position.row == lockedPosition.row and uncommittedMovePosition.position.col == lockedPosition.col) then
                movesAreSafe = false
                print("row: ", uncommittedMovePosition.position.row, " col: ", uncommittedMovePosition.position.col, " is locked")
                break
            end
            local valuePositionBeforeMoveSet = FindValueInState(stateSnapshot, value)
        
            if (isMoveTargetValueSafetyEnabled == true and (uncommittedMovePosition.position.row == valuePositionBeforeMoveSet.row and uncommittedMovePosition.position.col == valuePositionBeforeMoveSet.col)) then
                print("Avoid moving the target value. Rolling back.")
                movesAreSafe = false
                break
            end
        end
    end
    return movesAreSafe
end

local function revertState(revertTarget)
    print("Locked move detected. Reverting state to below")
    currentState = revertTarget
    blankPosition = FindValueInState(currentState, BLANK_SPACE_VALUE)
    UNCOMMITTEDMOVES = {}
    prettyPrint(currentState)
end

local function commitMoves() 
    for index, uncommittedMovePosition in ipairs(UNCOMMITTEDMOVES) do
        table.insert(MOVES, uncommittedMovePosition)
    end
    UNCOMMITTEDMOVES = {}
end

local function movementAlgorithm(useSpace, direction, value)
    print("BEGINNING MOVEMENT")
    if (direction == "LEFT" or direction == "RIGHT") then
        if (direction == "RIGHT") then
            moveBlankLeft()
        elseif (direction == "LEFT") then
            moveBlankRight()
        end
        if (useSpace == "BELOW") then
            moveBlankDown()
        elseif (useSpace == "ABOVE") then
            moveBlankUp()
        end
        if (direction == "RIGHT") then
            moveBlankRight()
            moveBlankRight()
        elseif (direction == "LEFT") then
            moveBlankLeft()
            moveBlankLeft()
        end
        if (useSpace == "BELOW") then
            moveBlankUp()
        elseif (useSpace == "ABOVE") then
            moveBlankDown()
        end
    elseif (direction == "UP" or direction == "DOWN") then
        if (direction == "UP") then
            moveBlankDown()
        elseif (direction == "DOWN") then
            moveBlankUp()
        end
        if (useSpace == "LEFT") then
            moveBlankLeft()
        elseif (useSpace == "RIGHT") then
            moveBlankRight()
        end
        if (direction == "DOWN") then
            moveBlankDown()
            moveBlankDown()
        elseif (direction == "UP") then
            moveBlankUp()
            moveBlankUp()
        end
        if (useSpace == "LEFT") then
            moveBlankRight()
        elseif (useSpace == "RIGHT") then
            moveBlankLeft()
        end
    end
end

local function moveBlankRelativeToValueX(value, colDifference, rowDifference)
    local valuePosition = FindValueInState(currentState, value)
    print(blankPosition.col)
    print(valuePosition.col)
    print(blankPosition.row)
    print(valuePosition.row)
    print(rowDifference)
    print(colDifference)
    while(blankPosition.col ~= valuePosition.col + colDifference or blankPosition.row ~= valuePosition.row + rowDifference) do
        -- backup state so we can dry run some routes
        while (blankPosition.col ~= valuePosition.col + colDifference) do

            local restorePoint = deepCopy(currentState)
            local delta = { deltaCol = valuePosition.col + colDifference - blankPosition.col, deltaRow = valuePosition.row + rowDifference - blankPosition.row}
            print("We need to move columns: ", delta.deltaCol, " and rows1: ", delta.deltaRow)
            
            if (delta.deltaCol > 0) then
                moveBlankRight()
            elseif (delta.deltaCol < 0) then
                moveBlankLeft()
            end
            if (movesAreSafe(true, restorePoint, value)) then
                commitMoves()
                restorePoint = deepCopy(currentState)
            else
                revertState(restorePoint)
                print("Moving to the right side of the board and trying again")
                if (blankPosition.row + 1 <= #desiredState) then
                    moveBlankDown()
                end
                while (blankPosition.col ~= #desiredState) do
                    moveBlankRight()
                end
                if (movesAreSafe(true, restorePoint, value)) then
                    commitMoves()
                    restorePoint = deepCopy(currentState)
                else
                    revertState(restorePoint)
                    print("Moving up one and trying again")
                    if (blankPosition.row - 1 >= 0) then
                        moveBlankUp()
                    end
                end
            end
            valuePosition = FindValueInState(currentState, value)
        end
        -- stop if the column is the same to avoid an infinite loop
        while (blankPosition.row ~= valuePosition.row + rowDifference) do

            local restorePoint = deepCopy(currentState)
            local delta = { deltaCol = valuePosition.col - blankPosition.col, deltaRow = valuePosition.row + rowDifference - blankPosition.row}
            print("We need to move columns: ", delta.deltaCol, " and rows3: ", delta.deltaRow)
            
            if (delta.deltaRow > 0) then
                moveBlankDown()
            elseif (delta.deltaRow < 0) then
                moveBlankUp()
            end
            if (movesAreSafe(true, restorePoint, value)) then
                commitMoves()
                restorePoint = deepCopy(currentState)
            else
                revertState(restorePoint)
                print("Moving to the right side of the board and trying again")
                print(blankPosition.row)
                print(#desiredState)
                if (blankPosition.row + 1 <= #desiredState) then
                    moveBlankDown()
                end
                if (blankPosition.col + 1 < #desiredState) then
                    while (blankPosition.col ~= #desiredState) do
                        moveBlankRight()
                    end
                else
                    moveBlankLeft()
                    moveBlankUp()
                end
                if (movesAreSafe(true, restorePoint, value)) then
                    commitMoves()
                    restorePoint = deepCopy(currentState)
                else
                    revertState(restorePoint)
                    print("Moving up one and trying again")
                    if (blankPosition.row - 1 >= 0) then
                        moveBlankUp()
                    end
                end
            end
            
            valuePosition = FindValueInState(currentState, value)
        end
    end
end

local function moveTileToDesiredPosition(value, colModifier, rowModifier) -- Hack to make the last tile in the row slot in easier
    prettyPrint(currentState)
    print("Tryign to move: ", value)
    -- get the directions the value needs to move to arrive
    local currentTilePosition = FindValueInState(currentState, value)
    local desiredTilePosition = FindValueInState(desiredState, value)
    desiredTilePosition.col = desiredTilePosition.col + colModifier
    desiredTilePosition.row = desiredTilePosition.row + rowModifier
    local stateSnapshot = deepCopy(currentState)

    local delta = { deltaCol = desiredTilePosition.col - currentTilePosition.col, deltaRow = desiredTilePosition.row - currentTilePosition.row }
    while (currentTilePosition.row ~= desiredTilePosition.row or currentTilePosition.col ~= desiredTilePosition.col) do
        stateSnapshot = deepCopy(currentState)
    -- if we need to go left, then move the position to the left of the desired tile
        if (delta.deltaCol < 0) then
            moveBlankRelativeToValueX(value, -1, 0)
            while (currentTilePosition.row ~= desiredTilePosition.row or currentTilePosition.col ~= desiredTilePosition.col) do
                print("NEW LOOP: ", currentTilePosition.col, " ", currentTilePosition.row)
                delta = { deltaCol = desiredTilePosition.col - currentTilePosition.col, deltaRow = desiredTilePosition.row - currentTilePosition.row }
                stateSnapshot = deepCopy(currentState)
                if (delta.deltaCol == 0) then
                    print("No column movement needed")
                    break
                elseif (delta.deltaCol == -1) then
                    moveBlankRight()
                else
                    movementAlgorithm("BELOW", "LEFT", value)
                    if (movesAreSafe(false, stateSnapshot, value)) then
                        commitMoves()
                    else
                        revertState(stateSnapshot)
                        print("Trying to reverse return direction to get move safety")
                        movementAlgorithm("ABOVE", "LEFT", value)
                    end
                end
                currentTilePosition = FindValueInState(currentState, value)
                desiredTilePosition = FindValueInState(desiredState, value)
                desiredTilePosition.col = desiredTilePosition.col + colModifier
                desiredTilePosition.row = desiredTilePosition.row + rowModifier
            end
        end
        if (delta.deltaCol > 0) then
            moveBlankRelativeToValueX(value, 1, 0)
            while (currentTilePosition.row ~= desiredTilePosition.row or currentTilePosition.col ~= desiredTilePosition.col) do
                stateSnapshot = deepCopy(currentState)
                print("NEW LOOP: ", currentTilePosition.col, " ", currentTilePosition.row)
                prettyPrint(currentState)
                delta = { deltaCol = desiredTilePosition.col - currentTilePosition.col, deltaRow = desiredTilePosition.row - currentTilePosition.row }
                stateSnapshot = deepCopy(currentState)
                if (delta.deltaCol == 0) then
                    print("No column movement needed")
                    break
                elseif (delta.deltaCol == 1) then
                    print("here")
                    moveBlankLeft()
                else
                    movementAlgorithm("ABOVE", "RIGHT", value)
                    if (movesAreSafe(false, stateSnapshot, value) and blankPosition.col + 1 <= #desiredState) then
                        commitMoves()
                    else
                        revertState(stateSnapshot)
                        print("Trying to revese return direction to get move safety")
                        movementAlgorithm("ABOVE", "RIGHT", value)
                    end
                end
                currentTilePosition = FindValueInState(currentState, value)
                desiredTilePosition = FindValueInState(desiredState, value)
                desiredTilePosition.col = desiredTilePosition.col + colModifier
                desiredTilePosition.row = desiredTilePosition.row + rowModifier
            end
        end
        if (delta.deltaRow < 0) then
            moveBlankRelativeToValueX(value, 0, -1)
            -- break
            while (currentTilePosition.row ~= desiredTilePosition.row or currentTilePosition.col ~= desiredTilePosition.col) do
                print("NEW LOOP: ", currentTilePosition.col, " ", currentTilePosition.row)
                prettyPrint(currentState)
                delta = { deltaCol = desiredTilePosition.col - currentTilePosition.col, deltaRow = desiredTilePosition.row - currentTilePosition.row }
                stateSnapshot = deepCopy(currentState)
                if (delta.deltaRow == 0) then
                    print("No row movement needed")
                    break
                elseif (delta.deltaRow == -1) then
                    moveBlankDown()
                else
                    movementAlgorithm("RIGHT", "UP", value)
                    if (movesAreSafe(false, stateSnapshot, value)) then
                        commitMoves()
                    else
                        revertState(stateSnapshot)
                        print("Trying to revese return direction to get move safety")
                        movementAlgorithm("LEFT", "UP", value)
                    end
                end
                currentTilePosition = FindValueInState(currentState, value)
                desiredTilePosition = FindValueInState(desiredState, value)
                desiredTilePosition.col = desiredTilePosition.col + colModifier
                desiredTilePosition.row = desiredTilePosition.row + rowModifier
            end
        end
        if (delta.deltaRow > 0) then
            moveBlankRelativeToValueX(value, 0, 1)
            -- break
            while (currentTilePosition.row ~= desiredTilePosition.row or currentTilePosition.col ~= desiredTilePosition.col) do
                print("NEW LOOP: ", currentTilePosition.col, " ", currentTilePosition.row)
                prettyPrint(currentState)
                delta = { deltaCol = desiredTilePosition.col - currentTilePosition.col, deltaRow = desiredTilePosition.row - currentTilePosition.row }
                stateSnapshot = deepCopy(currentState)
                if (delta.deltaRow == 0) then
                    print("No row movement needed")
                    break
                elseif (delta.deltaRow == 1) then
                    moveBlankUp()
                else
                    movementAlgorithm("RIGHT", "DOWN", value)
                    if (movesAreSafe(false, stateSnapshot, value)) then
                        commitMoves()
                    else
                        revertState(stateSnapshot)
                        print("Trying to revese return direction to get move safety")
                        movementAlgorithm("LEFT", "DOWN", value)
                    end
                end
                currentTilePosition = FindValueInState(currentState, value)
                desiredTilePosition = FindValueInState(desiredState, value)
                desiredTilePosition.col = desiredTilePosition.col + colModifier
                desiredTilePosition.row = desiredTilePosition.row + rowModifier
            end
        end
        print("DONE")
    end
    table.insert(LockedPositions, FindValueInState(currentState, value))
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

    -- solve 1
    moveTileToDesiredPosition(1, 0, 0)
    moveTileToDesiredPosition(2, 0, 0)
    moveTileToDesiredPosition(3, 0, 0)
    moveTileToDesiredPosition(4, 1, 0)
    moveTileToDesiredPosition(5, 1, 0)



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

calculateMoveSetToSolveTopRow()
for index, move in ipairs(MOVES) do
    print(move.direction)
end