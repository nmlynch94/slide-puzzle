require("test")

local currentState = {
    {6, 20, 1, 4, 5},
    {2, 8, 3, 9, 10},
    {11, 7, 13, 14, 15},
    {16, 12, 18, 19, 0},
    {21, 21, 22, 23, 24},
}

local desiredState = {
    {1, 2, 3, 4, 5},
    {6, 7, 8, 9, 10},
    {11, 12, 13, 14, 15},
    {16, 17, 18, 19, 20},
    {21, 22, 23, 24, 0},
}

-- FindValueInCurrentState
local testValue = FindValueInState(currentState, 1)
if (testValue.row ~= 1 or testValue.col ~= 3) then
    print(testValue.row, ": ", testValue.col)
    error("Didn't work")
end
print("-----------------END-------------------")

local testValue = FindValueInState(currentState, 13)
if (testValue.row ~= 3 or testValue.col ~= 3) then
    print(testValue.row, ": ", testValue.col)
    error("Didn't work")
end
print("-----------------END-------------------")

-- Try to move value that doesn't need moveBlankDown
local value = moveCol(4, currentState, desiredState, 0)
if (value ~= "No movement needed") then
    print(value)
    error("Didn't work")
end
print("-----------------END-------------------")

-- Try to move blank position relative to several values to the left
local state = moveCol(1, currentState, desiredState, 0)
local blankPosition = FindValueInState(currentState, 0)
if (blankPosition.col ~= 2) then
    error("Didn't work")
end
prettyPrint(state)
print("-----------------END-------------------")

-- Try to move blank position relative to values to the left and it needs a vertical adjustment to get there.
local testState = {
    {10, 20, 1, 4, 5},
    {2, 8, 6, 9, 0},
    {11, 7, 13, 14, 15},
    {16, 12, 18, 19, 3},
    {21, 21, 22, 23, 24},
}
local state = moveCol(6, testState, desiredState, 0)
local blankPosition = FindValueInState(testState, 0)
local targetPosition = FindValueInState(testState, 6)
if ((blankPosition.col ~= 2 or blankPosition.row ~= 2) or (targetPosition.col ~= 3 or targetPosition.row ~= 2)) then
    error("Didn't work")
end
prettyPrint(state)
print("-----------------END-------------------")

print("Start test moving left with a necessary vertical adjustment down to avoid the target of 6")
local testState = {
    {8, 20, 1, 4, 5},
    {2, 10, 6, 9, 0},
    {11, 7, 13, 14, 15},
    {16, 12, 18, 19, 3},
    {21, 21, 22, 23, 24},
}
prettyPrint(testState)
local state = moveCol(6, testState, desiredState, 0)
local blankPosition = FindValueInState(testState, 0)
local targetPosition = FindValueInState(testState, 6)
if ((blankPosition.col ~= 2 or blankPosition.row ~= 2) or (targetPosition.col ~= 3 or targetPosition.row ~= 2)) then
    error("Didn't work")
end
prettyPrint(state)
print("-----------------END-------------------")

print("Start test moving left with a necessary vertical adjustment up to avoid the target of 22")
local testState = {
    {10, 20, 1, 4, 5},
    {2, 8, 6, 9, 21},
    {11, 7, 13, 14, 15},
    {16, 12, 18, 19, 3},
    {24, 21, 23, 22, 0},
}
local state = moveCol(22, testState, desiredState, 0)
local blankPosition = FindValueInState(testState, 0)
local targetPosition = FindValueInState(testState, 22)
if ((blankPosition.col ~= 3 or blankPosition.row ~= 5) or (targetPosition.col ~= 4 or targetPosition.row ~= 5)) then
    error("Didn't work")
end
prettyPrint(state)
print("-----------------END-------------------")

print("Testing moving both left and up")
local testState = {
    {10, 20, 1, 4, 5},
    {2, 8, 6, 9, 21},
    {11, 7, 13, 14, 15},
    {16, 12, 18, 19, 3},
    {24, 21, 23, 22, 0},
}
local state = moveCol(1, testState, desiredState, 0)
local blankPosition = FindValueInState(testState, 0)
local targetPosition = FindValueInState(testState, 1)
if ((blankPosition.col ~= 2 or blankPosition.row ~= 1) or (targetPosition.col ~= 3 or targetPosition.row ~= 1)) then
    error("Didn't work")
end
prettyPrint(state)
print("-----------------END-------------------")

print("Testing moving both left and down")
local testState = {
    {10, 20, 1, 4, 0},
    {2, 8, 6, 9, 21},
    {11, 7, 13, 14, 15},
    {16, 12, 18, 19, 3},
    {24, 21, 23, 22, 5},
}
local state = moveCol(22, testState, desiredState, 0)
local blankPosition = FindValueInState(testState, 0)
local targetPosition = FindValueInState(testState, 22)
if ((blankPosition.col ~= 3 or blankPosition.row ~= 5) or (targetPosition.col ~= 4 or targetPosition.row ~= 5)) then
    error("Didn't work")
end
prettyPrint(state)
print("-----------------END-------------------")
