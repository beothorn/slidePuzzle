# Slide Puzzle

A godot plugin to create puzzles with sliding pieces.

The idea is to have pieces that can only slide through fixed paths and need to be moved to the goal.

You can have many pieces that work on many goals or a goal for eac piece.


## How to use it

Add a new SlidePuzzle component.

SlidePuzzle is a TileMap, it will be the path on which all pieces are allowed to slide.

Create a tileset for it and set the cell size.

Add a child node Node and name it Pieces.

For each piece type add a child node. 

So for example if you have a red piece and a blue piece you would add a Node Blue and a node Red.

Inside each piece node you also need two nodes Pieces and Goals

On Pieces add the sprites for the pieces. They should have the cell size of SlidePuzzle and should be aligned with the grid.

On Goals add the sprites for the goals. Also should have the same cell size and be aligned.

SlidePuzzle
|
-Pieces
 |
 |-Blue
   |-Pieces
     |-BlueSprite
   |-Goals
     |-BlueSpriteGoal
 |-Red
   |-Pieces
     |-RedSprite
   |-Goals
     |-RedSpriteGoal


