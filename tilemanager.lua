local class = require("30log");

local TILES_PATH = "tiles/"; -- or any path depending on your project

local tilemanager = class("tilemanager", {
  map = nil,
  lastGotTile = 0,
  layers = {},
  objects = {},
  width = 0,
  height = 0,
  tilewidth = 0,
  tileheight = 0,
  tilesets = {},
  quads = {},
  cache = {},
  collidables = {},
  cacheCount = 0,
  cacheOn = false,

});

local _stringify = function(tabel)
  local s = "";
  for _,v in ipairs(tabel) do
      s = s .. v .. ",";
  end
  return s;
end

tilemanager.initTileSets = function(self, tilesets, lg)
  local i = 1;
  for _,tileset in ipairs(tilesets) do
    local tile = {
      name = tileset.name,
      image = lg.newImage(TILES_PATH..tileset.name),
      Qnumber = 0,
    }
    tile.image:setFilter('nearest', 'nearest');
    self.tilesets[i] = tile;
    i = i + 1;
  end
end

tilemanager.initLayers = function(self, layers, lg)
  local whitespace = "%s";
  local void = "";
  for i,layer in ipairs(layers) do
    if layer.type == "tilelayer" and layer.name ~= "collidables" then
      table.insert(self.layers,{
        name = layer.name,
        data = _stringify(layer.data):gsub(whitespace, void),
        width = layer.width,
        height = layer.height
      });
    end
  end
end

tilemanager.initObjects = function(self, layers, lg)
  for _,layer in ipairs(layers) do
    if layer.type == "objectgroup" then
      for _,object in ipairs(layer["objects"]) do
        table.insert(self.objects,{
          name = object.name,
          x = object.x,
          y = object.y
        });
      end
    end
  end
end

tilemanager.initQuads = function(self, lg)
  for i, tile in ipairs(self.tilesets) do
    local image = tile.image;
    for tileY = 0, (image:getHeight() / self.tileheight) - 1 do
      for tileX = 0, (image:getWidth() / self.tilewidth) - 1 do
        local quad = lg.newQuad(
          tileX * self.tilewidth
        , tileY * self.tileheight
        , self.tilewidth
        , self.tileheight
        , image:getDimensions());
        table.insert(self.quads, quad);
        self.tilesets[i].Qnumber = self.tilesets[i].Qnumber + 1;
      end
    end
  end
end

tilemanager.drawCache = function(self, x, y, index, tilePos)
  self.cacheCount = self.cacheCount + 1;
  self.cache[x+y..tilePos] = {
    index,
    tilePos
  };
end

tilemanager.drawTile = function(self, x, y, tilePos)

  local lg = love.graphics;

  if self.cacheOn then
    if self.cache[x+y..tilePos] then
      lg.draw(self.tilesets[self.cache[x+y..tilePos][1]].image, self.quads[self.cache[x+y..tilePos][2]], x, y);
      return;
    end
  end

  local index = 1;
  local multi = 0; 
  local lastTileQuads = self.tilesets[index].Qnumber; -- Hold the last tile quads
  local size = self.tilesets[index].Qnumber;

  while index <= #self.tilesets  do
    if tilePos < #self.quads + 1 and tilePos <  size  then
       if self.cacheOn then self:drawCache(x ,y ,index ,tilePos) end
       local newI = x..y;
       if self.collidables[tonumber(tilePos)] and self.collidables[tonumber(tilePos)][newI] == nil then
        self.collidables[tonumber(tilePos)][newI] = newI;
       end
      lg.draw(self.tilesets[index].image, self.quads[tilePos], x, y);
      return;
    else
      lastTileQuads = lastTileQuads + self.tilesets[index].Qnumber;
      index = index + 1;
      size = ((self.tilesets[index].Qnumber * multi) + lastTileQuads) + 1;
      multi = multi + 1;
    end
  end

end

tilemanager.initCollidables = function(self, layers)
  for _,layer in ipairs(layers) do
    if layer.type == "tilelayer" and layer.name == "collidables" then
      for _,tile in ipairs(layer.data) do
        if tile ~= 0 then
          self.collidables[tile] = {};
        end
      end
    end
  end
end

tilemanager.isWalkable = function(self, pos)
  for k,_ in pairs(self.collidables) do
    if self.collidables[k][pos] then return false end
  end
  return true;
end

tilemanager.isTileWalkable = function(self, x, y)
  local xx = math.floor((x + self.tilewidth) / self.tilewidth - 1) * self.tilewidth;
  local yy = math.floor((y + self.tileheight) / self.tileheight - 1)  * self.tileheight;
  return self:isWalkable(xx..yy);
end

tilemanager.initAll = function(self, Tdata, lg)
  self:initTileSets(Tdata.tilesets, lg);
  self:initLayers(Tdata.layers, lg);
  self:initObjects(Tdata.layers, lg);
  self:initCollidables(Tdata.layers);
  self:initQuads(lg);
end

local seperateS = function(s)
  local output = {};
  for match in s:gmatch("([%d%.%+%-]+),?") do
    output[#output + 1] = tonumber(match);
  end
  return output;
end

tilemanager.draw = function(self)
  for _, layer in ipairs(self.layers) do
    local data = seperateS(layer.data);
    for i = 1 , #data do
      local tilePos = data[i]; -- 1D

      local x = ((i-1) % layer.width ) * self.tilewidth;
      local y = math.floor((i-1) / layer.width) * self.tileheight;

      if tilePos ~= 0 then
        self:drawTile(x, y, tilePos, i);
      end
    end
  end
end

tilemanager.init = function(self, tiledFilePath)
  local data  = require(tiledFilePath);
  local lg = love.graphics;
  self.width = data.width;
  self.height = data.height;
  self.tilewidth = data.tilewidth;
  self.tileheight = data.tileheight;
  local Tdata = data;
  self:initAll(Tdata, lg);
end

return tilemanager;
