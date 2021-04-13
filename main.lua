local tilemanager = require("tilemanager");
local tm = tilemanager("level1");


function love.draw()
  tm:draw()
end
