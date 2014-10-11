LEVEL = {}

--level constructor
function LEVEL:new()
	local level = {}
	setmetatable(level,{__index=self})
	level.blocks = {}
	level.sources = {}
	level.edges = {}
	return level
end

--draws each block and source of light
function LEVEL:draw()
	love.graphics.setColor(0,0,255,255)
	for i = 1,#self.blocks do
		love.graphics.rectangle("fill",self.blocks[i][1],self.blocks[i][2],self.blocks[i][3],self.blocks[i][4])
	end
	love.graphics.setColor(255,255,255,255)
	for i = 1,#self.sources do
		self.sources[i]:draw()
	end
end

--adds a block to the level
function LEVEL:addBlock(block)
	table.insert(self.blocks,block)
end

function LEVEL:addSource(source)
	table.insert(self.sources,source)
end

--removes block at (x,y)
function LEVEL:removeBlock(x,y)
	for i = #self.blocks,1,-1 do
		if x > self.blocks[i][1] and x < self.blocks[i][1] + self.blocks[i][3] and y > self.blocks[i][2] and y < self.blocks[i][2] + self.blocks[i][4] then
			table.remove(self.blocks,i)
			return true
		end
	end
	return false
end

--removes source of light at (x,y)
function LEVEL:removeSource(x,y)
	for i = #self.sources,1,-1 do
		if self.sources[i]:containsPoint(x,y) then
			table.remove(self.sources,i)
			return true
		end
	end
	return false
end

--rotates source of lights direction at (x,y)
function LEVEL:rotateSource(x,y)
	for i = #self.sources,1,-1 do
		if self.sources[i]:containsPoint(x,y) then
			if self.sources[i].direction[1] == 1 and self.sources[i].direction[2] == 0 then
				self.sources[i].direction[1] = 0
				self.sources[i].direction[2] = 1
			elseif self.sources[i].direction[1] == 0 and self.sources[i].direction[2] == 1 then
				self.sources[i].direction[1] = -1
				self.sources[i].direction[2] = 0
			elseif self.sources[i].direction[1] == -1 and self.sources[i].direction[2] == 0 then
				self.sources[i].direction[1] = 0
				self.sources[i].direction[2] = -1
			elseif self.sources[i].direction[1] == 0 and self.sources[i].direction[2] == -1 then
				self.sources[i].direction[1] = 0
				self.sources[i].direction[2] = 0
			elseif self.sources[i].direction[1] == 0 and self.sources[i].direction[2] == 0 then
				self.sources[i].direction[1] = 1
				self.sources[i].direction[2] = 0
			end
		end
	end
end

--change source of lights radius
function LEVEL:changeSourceRadius(x,y,amt)
	for i = #self.sources,1,-1 do
		if self.sources[i]:containsPoint(x,y) then
			self.sources[i].radius = math.max(self.sources[i].radius + amt,0)
		end
	end
end
