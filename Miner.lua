-- 1 argument - tunel height
-- 2 argument - max tunnel length (in right direction)
-- 3 argument - tunels period in blocks

local height = tonumber(arg[1])
local length = tonumber(arg[2])
local tunnel_steps = tonumber(arg[3])

-- Уникальный ID черепахи
local id = os.getComputerID()
local modemSide = "back"
local hasModem = peripheral.getType(modemSide) == "modem"

local function isOre(blockName)
  return blockName and blockName:match("_ore$")
end

local function inspectAndDig(direction)
  local inspect, dig, move, back

  if direction == "front" then
    inspect = turtle.inspect
    dig = turtle.dig
    move = turtle.forward
    back = turtle.back
  elseif direction == "up" then
    inspect = turtle.inspectUp
    dig = turtle.digUp
    move = turtle.up
    back = turtle.down
  elseif direction == "down" then
    inspect = turtle.inspectDown
    dig = turtle.digDown
    move = turtle.down
    back = turtle.up
  elseif direction == "left" then
    turtle.turnLeft()
    local found = inspectAndDig("front")
    turtle.turnRight()
    return found
  elseif direction == "right" then
    turtle.turnRight()
    local found = inspectAndDig("front")
    turtle.turnLeft()
    return found
  end

  local ok, data = inspect()
  if ok and isOre(data.name) then
    dig()
    while not move() do
      dig()
      sleep(0.2)
    end
    checkOres()
    back()
    return true
  end


  return false
end

function checkOres()
  inspectAndDig("front")
  inspectAndDig("up")
  inspectAndDig("down")
  inspectAndDig("left")
  inspectAndDig("right")
end

local trashBlocks = {
  ["minecraft:cobblestone"] = true,
  ["minecraft:mossy_cobblestone"] = true,
  ["minecraft:cobbled_deepslate"] = true,
  ["minecraft:deepslate"] = true,
  ["minecraft:tuff"] = true,
  ["minecraft:granite"] = true,
  ["minecraft:diorite"] = true,
  -- do NOT include andesite
}

local function dropTrashBlocks()
  for slot = 1, 16 do
    turtle.select(slot)
    local detail = turtle.getItemDetail()
    if detail and trashBlocks[detail.name] then
      turtle.dropDown()
    end
  end
  turtle.select(1)
end

local function forwardDig(height)
	while not turtle.forward() do
		turtle.dig()
		sleep(0.2)
	end
	checkOres()
	for i = 2, height do
		while not turtle.up() do
			turtle.digUp()
			sleep(0.2)
		end
		checkOres()
	end
	for i = 2, height do
		while not turtle.down() do
			turtle.digDown()
			sleep(0.2)
		end
	end
end

local function goForward(blocks)
	for i = 1, blocks do
	  while not turtle.forward() do
		turtle.dig()
		sleep(0.2)
	  end
	end
end

local function goForwardTunel(blocks)
  for i = 1, blocks do
    while not turtle.forward() do
      turtle.dig()
      sleep(0.2)
    end
    while turtle.detectUp() do
      turtle.digUp()
    end
  end
end


local function isInventoryFull()
  for slot = 1, 16 do
    if turtle.getItemCount(slot) == 0 then
      return false
    end
  end
  return true
end


local function mineTunnel(length, height)
  local forward_digged = 0
  for i = 1, length do
    forwardDig(height)
	dropTrashBlocks()
    forward_digged = forward_digged + 1

    if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < 500 then
      print("Low fuel: returning early.")
      turtle.turnLeft()
      turtle.turnLeft()
      goForward(forward_digged)
      turtle.turnLeft()
      turtle.turnLeft()
      return forward_digged
    end

    if isInventoryFull() then
      print("Inventory full: returning.")
      turtle.turnLeft()
      turtle.turnLeft()
      goForward(forward_digged)
      turtle.turnLeft()
      turtle.turnLeft()
      return forward_digged
    end
  end
  return forward_digged
end

local function refuelAndUnload()
  turtle.turnRight()
  for slot = 1, 16 do
    turtle.select(slot)
    if turtle.getItemCount(slot) > 0 then
      turtle.drop()
    end
  end
  
  turtle.turnLeft()
  if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < 2000 then
    print("Fuel low, refueling...")
    turtle.turnLeft()

    for slot = 1, 16 do
      turtle.select(slot)
      if turtle.getItemCount(slot) == 0 then
        if turtle.suck(64) then
          if turtle.refuel() then
            print("Refueled from left chest.")
            break
          else
            print("Item not valid fuel.")
            turtle.drop()
          end
        end
      end
    end

    turtle.turnRight()
  end

  turtle.select(1)
end

-- Отправка сообщения по сети
local function sendStatus(message)
  if hasModem and rednet.isOpen(modemSide) then
    local id = os.getComputerID()
    rednet.broadcast("[Turtle #" .. id .. "] " .. message)
  end
end

local function checkSurround()
  turtle.turnLeft()
  if turtle.detect() then
    return "left"
  end

  turtle.turnRight()
  turtle.turnRight()
  if turtle.detect() then
    return "right"
  end
  turtle.turnLeft()

  return "forward"
end

local function goToStartPosition(digged_blocks, blocks_to_offset, height)
  sendStatus("Go to starting tunel position")
  goForward(digged_blocks)
  local dig_direction = checkSurround()
  while dig_direction == "forward" do
	print(dig_direction)
	if dig_direction == "forward" then
		goForwardTunel(blocks_to_offset)
		digged_blocks = digged_blocks + blocks_to_offset
	end
	dig_direction = checkSurround()
  end
  return digged_blocks, dig_direction
end

local function goToHome(blocks_to_home, direction)
  sendStatus("Go to home")
  if direction == "left" then
    turtle.turnRight()
  elseif direction == "right" then
    turtle.turnLeft()
  end
  goForward(blocks_to_home)
  turtle.turnRight()
  turtle.turnRight()
end

local function isInventoryEmpty()
  for slot = 1, 16 do
    if turtle.getItemCount(slot) > 0 then
      return false
    end
  end
  return true
end

local function abortIfNeedsResupply()
  local fuel = turtle.getFuelLevel()
  local needsRefuel = fuel ~= "unlimited" and fuel < 1000
  local hasItems = not isInventoryEmpty()

  if needsRefuel or hasItems then
    print("== Awaiting user action ==")
    if needsRefuel then
      print("Fuel low: " .. fuel)
      sendStatus("Waiting for refuel (fuel = " .. fuel .. ")")
    end
    if hasItems then
      print("Inventory not empty")
      sendStatus("Waiting for unload (inventory not empty)")
    end
    print("Press any key to continue...")

    os.pullEvent("key")  -- pause until key press
    return false
  end
  return true
end

local starting_position = 1
--local tunnel_steps = 3
--local height = 1
--local length = 1

while true do
  if hasModem then rednet.open(modemSide) end
  
  refuelAndUnload()
  while abortIfNeedsResupply() == false do
    if hasModem then rednet.close(modemSide) end
    refuelAndUnload()
    if hasModem then rednet.open(modemSide) end
  end

  local fuel = turtle.getFuelLevel()
  sendStatus("Starting tunnel work (fuel = " .. fuel .. ")")

  if hasModem then rednet.close(modemSide) end

  new_start, direction = goToStartPosition(starting_position, tunnel_steps, height)
  local block_mined = mineTunnel(length, height)
  turtle.turnLeft()
  turtle.turnLeft()
  goForward(block_mined)
  goToHome(new_start, direction)
  starting_position = new_start
  print(new_start)
end
