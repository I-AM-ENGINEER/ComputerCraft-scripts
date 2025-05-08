-- NetherChunkDestroyer.lua
-- Скрипт для ComputerCraft, который едет вперед, пока не наткнется на блок,
-- затем копает вниз на указанное количество блоков.

local tArgs = { ... }

-- Проверяем, передан ли аргумент
if #tArgs < 1 then
    print("Usage: NetherChunkDestroyer <N>")
    return
end

-- Количество блоков для копания вниз
local depth = tonumber(tArgs[1])
if not depth or depth <= 0 then
    print("Error: N must be a positive number.")
    return
end

local function goForward(blocks)
	for i = 1, blocks do
	    while not turtle.forward() do
		    turtle.dig()
		    sleep(0.2)
	    end
	end
end

local function goDown(blocks)
	for i = 1, blocks do
	    while not turtle.down() do
		    turtle.digDown()
		    sleep(0.2)
	    end
	end
end

local function goUp(blocks)
	for i = 1, blocks do
	    while not turtle.up() do
		    turtle.digUp()
		    sleep(0.2)
	    end
	end
end

local function digDownN(n)
    for i = 1, n do
        turtle.digDown()
        goDown(1)
    end
end


local function findBlock(max_len)
    local forward_blocks = 0
    while not turtle.detect() do
        goForward(1)
        forward_blocks = forward_blocks + 1

        if forward_blocks > max_len then
            return -1
        end
    end
    return forward_blocks
end

local function isInventoryEmpty()
    for slot = 1, 16 do
      if turtle.getItemCount(slot) > 0 then
        return false
      end
    end
    return true
  end

local function refuelAndUnload()
    turtle.turnLeft()
    turtle.turnLeft()
    for slot = 1, 16 do
      turtle.select(slot)
      if turtle.getItemCount(slot) > 0 then
        turtle.drop()
      end
    end
    
    if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < 2000 then
      print("Fuel low, refueling...")
  
      for slot = 1, 16 do
        turtle.select(slot)
        if turtle.getItemCount(slot) == 0 then
          if turtle.suckUp(64) then
            if turtle.refuel() then
              print("Refueled from up chest.")
              break
            else
              print("Item not valid fuel.")
              turtle.drop()
            end
          end
        end
      end
    end
  
    turtle.select(1)

    turtle.turnLeft()
    turtle.turnLeft()
  end

local function abortIfNeedsResupply()
    local fuel = turtle.getFuelLevel()
    local needsRefuel = fuel ~= "unlimited" and fuel < 500
    local hasItems = not isInventoryEmpty()
  
    if needsRefuel or hasItems then
      print("== Awaiting user action ==")
      if needsRefuel then
        print("Fuel low: " .. fuel)
      end
      if hasItems then
        print("Inventory not empty")
      end
      print("Press any key to continue...")

      os.pullEvent("key")  -- pause until key press
      return false
    end
    return true
end


while true do
    refuelAndUnload()
    while abortIfNeedsResupply() == false do
        refuelAndUnload()
    end

    local forward_blocks = findBlock(100)
    if forward_blocks >= 0 then
        forward_blocks = forward_blocks + 1 
        goForward(1)
        digDownN(depth)
        goUp(depth)
    end
    turtle.turnLeft()
    turtle.turnLeft()
    goForward(forward_blocks)
    turtle.turnLeft()
    turtle.turnLeft()
    if forward_blocks < 0 then
        break
    end
end
print("Task completed.")
