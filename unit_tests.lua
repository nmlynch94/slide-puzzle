require("test")

local currentState = {
    {6, 0, 1, 4, 5},
    {2, 8, 3, 9, 10},
    {11, 7, 13, 14, 15},
    {16, 12, 18, 19, 20},
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

local testValue = FindValueInState(currentState, 13)
if (testValue.row ~= 3 or testValue.col ~= 3) then
    print(testValue.row, ": ", testValue.col)
    error("Didn't work")
end