require('light_source')
require('level')

function love.load()
	level = LEVEL:new()
	level:addSource(LIGHT_SOURCE:new(level,300,300,250,1,{0,0}))
	holding_item = false
end

function love.update(dt)


end

function love.draw()
	level:draw()
	if not holding_item then
		love.graphics.rectangle("line",love.mouse.getX() - 25,love.mouse.getY() - 25,50,50)
	else
		love.graphics.setColor(0,0,255,255)
		love.graphics.rectangle("fill",love.mouse.getX() - 25,love.mouse.getY() - 25,50,50)
		love.graphics.setColor(255,255,255,255)
	end
end

function love.mousepressed(x,y,button)
	if button == "l" then
		holding_item = level:removeBlock(x,y)
	elseif button == "wd" then
		level:changeSourceRadius(x,y,-50)
	elseif button == "wu" then
		level:changeSourceRadius(x,y,50)
	end
end

function love.mousereleased(x,y,button)
	if button == "l" then
		level:addBlock({x - 25,y - 25,50,50})
		holding_item = false
	elseif button == "r" then
		level:removeBlock(x,y)
		level:removeSource(x,y)

	end
end

function love.keyreleased(key)
	if key == "s" then
		level:addSource(LIGHT_SOURCE:new(level,love.mouse.getX(),love.mouse.getY(),500,1,{0,0}))
	elseif key == "r" then
		level:rotateSource(love.mouse.getX(),love.mouse.getY())
	end
end