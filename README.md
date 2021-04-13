# TileManager
Personal class (30log) i use for my current project to manage tilemaps data exported from Tiled in lua form. 

#### What it does :
* Associate the quad to the tileset where it exists.

  * In Tiled give the tilesets the same name as the image/source 

    * ex : 

      ![example](https://github.com/maromaroXD/TileManager/blob/master/example.png)

* It stores all quads in the same table independently of the tiles.

* Keeps track of collidables walls/non-walkables.

  * It is mandatory to create a layer named "collidables" where you basically define "collidable" tiles and then use them in your other layers.

    ![example](https://github.com/maromaroXD/TileManager/blob/master/collidable.png)

  * the layer "collidables" will not be drawn it is just a reference to the tiles that should be collidables.

* Keeps track of objects and there spawn positions.