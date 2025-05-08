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

-- Надежная функция движения вперед
local function safeForward()
    while not turtle.forward() do
        if turtle.detect() then
            turtle.dig()
        elseif turtle.attack() then
            -- Если впереди моб, атакуем
            print("Mob detected, attacking...")
        else
            print("Unable to move forward, retrying...")
            sleep(0.5)
        end
    end
end

-- Надежная функция копания вниз
local function digDownN(n)
    for i = 1, n do
        while not turtle.digDown() do
            if turtle.detectDown() then
                print("Block below detected, retrying dig...")
                sleep(0.5)
            else
                break
            end
        end
        if not turtle.down() then
            print("Unable to move down, retrying...")
            sleep(0.5)
            i = i - 1 -- Повторяем попытку
        end
    end
end

-- Основной алгоритм
while true do
    if turtle.detect() then
        print("Block detected ahead, starting to dig down...")
        digDownN(depth)
        break
    else
        safeForward()
    end
end

print("Task completed.")