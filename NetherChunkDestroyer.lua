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

-- Основной алгоритм

while true do
    local forward_blocks = findBlock(100)
    if forward_blocks >= 0 then
        digDownN(depth)
        goUp(depth)
    end
    turnLeft()
    turnLeft()
    goForward(forward_blocks)
    turnLeft()
    turnLeft()
    if forward_blocks < 0 then
        break
    end
end
print("Task completed.")