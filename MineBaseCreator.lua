-- Reliable function to move forward, breaking blocks if necessary
function moveForwardReliable()
    while not turtle.forward() do
        turtle.dig()
        sleep(0.5) -- Small delay to avoid infinite loops
    end
end

-- Function to create a vertical tunnel section 5x5 using a ComputerCraft turtle
function dig5x5Layer()
    for x = 1, 5 do
        for y = 1, 5 do
            turtle.digDown()
            if y < 5 then
                moveForwardReliable()
            end
        end
        -- Move back to the start of the row
        if x < 5 then
            if x % 2 == 1 then
                turtle.turnRight()
                moveForwardReliable()
                turtle.turnRight()
            else
                turtle.turnLeft()
                moveForwardReliable()
                turtle.turnLeft()
            end
        end
    end
    -- Move back to the starting position of the layer
    for _ = 1, 4 do
        turtle.back()
    end
    turtle.turnRight()
    for _ = 1, 4 do
        turtle.back()
    end
    turtle.turnLeft()
end


function createVerticalTunnel(targetY)
    while true do
        local _, y = gps.locate()
        if y == nil then
            print("GPS signal not found. Ensure the turtle has access to GPS.")
            return
        end
        if y <= targetY then
            break
        end
        dig5x5Layer()
        if y > targetY then
            -- Move down to the next layer
            turtle.down()
        end
    end
end

print("Step 1 - create vertical tunnel")
-- Example usage: Create a vertical tunnel 5x5 with a height of 10
createVerticalTunnel(10)



