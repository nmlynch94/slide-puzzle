# Project Name

PoC to programmatically solve a 5x5, 4x4, and 3x3 slide puzzle solver. It can currently handle 5x5 and 3x3 puzzles very easily, but I have not finished the implementation to make 4x4 fast. It uses ida* and may take a long time to solve depending on the complexity of the solution needed.

## How it works
3x3 and 4x4 puzzles can be solved feasibly using ida*. However, 5x5 the amount of paths we need to search becomes overly complex to feasibly do. To get around this, we use a combination of a* and pre-defined algorthims to move tiles across the board to solve columns and rows 1, and 2. Then, we use ida* on the remaining 3x3.

The heuristics I used are manhattan distance and linear conflicts

## Usage
see `lua main.lua --help`

example: `lua main.lua --state "18-21-23-7-24-8-14-3-17-15-6-9-20-4-22-13-2-1-12-16-10-19-11-5-0"`

output:
```
starting state: 18-21-23-7-24-8-14-3-17-15-6-9-20-4-22-13-2-1-12-16-10-19-11-5-0 : 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-0
moves: 302
LEFT, LEFT, LEFT, UP, RIGHT, DOWN, LEFT, LEFT, UP, RIGHT, 
UP, LEFT, DOWN, RIGHT, UP, UP, LEFT, DOWN, RIGHT, UP, 
UP, LEFT, DOWN, DOWN, DOWN, DOWN, RIGHT, RIGHT, UP, LEFT, 
DOWN, RIGHT, UP, UP, LEFT, DOWN, RIGHT, UP, UP, LEFT, 
DOWN, RIGHT, UP, UP, LEFT, DOWN, RIGHT, DOWN, LEFT, UP, 
RIGHT, DOWN, RIGHT, UP, UP, LEFT, DOWN, RIGHT, DOWN, LEFT, 
DOWN, RIGHT, RIGHT, UP, LEFT, UP, RIGHT, DOWN, LEFT, UP, 
UP, RIGHT, DOWN, DOWN, DOWN, DOWN, LEFT, UP, UP, RIGHT, 
DOWN, LEFT, UP, UP, RIGHT, DOWN, LEFT, UP, UP, RIGHT, 
DOWN, LEFT, LEFT, DOWN, DOWN, LEFT, DOWN, RIGHT, UP, LEFT, 
LEFT, DOWN, RIGHT, UP, LEFT, DOWN, RIGHT, UP, UP, LEFT, 
DOWN, RIGHT, UP, UP, LEFT, DOWN, RIGHT, RIGHT, DOWN, RIGHT, 
RIGHT, DOWN, LEFT, UP, UP, RIGHT, DOWN, LEFT, UP, RIGHT, 
DOWN, LEFT, LEFT, UP, RIGHT, DOWN, LEFT, LEFT, UP, RIGHT, 
DOWN, LEFT, LEFT, UP, RIGHT, DOWN, LEFT, DOWN, RIGHT, RIGHT, 
UP, LEFT, DOWN, RIGHT, RIGHT, UP, LEFT, RIGHT, DOWN, RIGHT, 
UP, LEFT, LEFT, DOWN, RIGHT, UP, LEFT, LEFT, DOWN, RIGHT, 
UP, LEFT, LEFT, DOWN, RIGHT, RIGHT, RIGHT, UP, LEFT, LEFT, 
DOWN, RIGHT, UP, LEFT, LEFT, DOWN, RIGHT, UP, UP, UP, 
RIGHT, RIGHT, DOWN, LEFT, LEFT, UP, RIGHT, DOWN, LEFT, DOWN, 
RIGHT, RIGHT, UP, UP, LEFT, DOWN, RIGHT, RIGHT, DOWN, LEFT, 
UP, RIGHT, DOWN, LEFT, UP, UP, RIGHT, DOWN, DOWN, DOWN, 
LEFT, LEFT, LEFT, UP, RIGHT, RIGHT, DOWN, LEFT, UP, RIGHT, 
RIGHT, DOWN, LEFT, UP, RIGHT, DOWN, LEFT, UP, UP, RIGHT, 
DOWN, LEFT, UP, UP, RIGHT, DOWN, LEFT, LEFT, LEFT, DOWN, 
RIGHT, DOWN, RIGHT, UP, LEFT, DOWN, RIGHT, UP, LEFT, LEFT, 
DOWN, RIGHT, UP, UP, RIGHT, DOWN, LEFT, UP, RIGHT, DOWN, 
DOWN, LEFT, UP, LEFT, DOWN, RIGHT, UP, RIGHT, DOWN, LEFT, 
UP, UP, RIGHT, DOWN, LEFT, UP, RIGHT, DOWN, RIGHT, UP, 
LEFT, DOWN, DOWN, RIGHT, UP, LEFT, DOWN, LEFT, UP, RIGHT,
```

On my machine it solves in an average of 253 moves in ~7 seconds for a randomly generated puzzle.