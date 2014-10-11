LIGHT_SOURCE = {}

--light source constructoe
function LIGHT_SOURCE:new(level,x,y,rad,pwr,dir)
	local source = {}
	setmetatable(source,{__index=self})
	source.level = level
	source.x = x
	source.y = y
	source.size = 10
	source.radius = rad
	source.power = pwr
	source.direction = dir
	return source
end

--draws the light source with the light source shader (found below)
function LIGHT_SOURCE:draw()
	local blocks = {}
	table.insert(blocks,{love.mouse.getX() - 25,love.window.getHeight() - love.mouse.getY() - 25,50,50})
	for i = 1,#self.level.blocks do
		table.insert(blocks,{self.level.blocks[i][1],love.window.getHeight() - self.level.blocks[i][2] - self.level.blocks[i][4],self.level.blocks[i][3],self.level.blocks[i][4]})
	end

	love.graphics.setShader(self.shader)
	love.graphics.setBlendMode("additive")
	self.shader:send("numBlocks",#blocks)
	self.shader:send("blocks",unpack(blocks))
	self.shader:send("light_pos",{self.x,love.window.getHeight() - self.y})
	self.shader:send("light_radius",self.radius)
	self.shader:send("light_power",self.power)
	self.shader:send("light_dir",self.direction)
	love.graphics.circle("fill",self.x + self.size/2,self.y + self.size/2,self.radius,100)
	love.graphics.setBlendMode("alpha")
	love.graphics.setShader()

	love.graphics.setColor(255,0,0,255)
	love.graphics.circle("line",self.x,self.y,self.size,100)
	love.graphics.setColor(255,255,255,255)
end

function LIGHT_SOURCE:containsPoint(x,y)
	if (self.x - x)*(self.x - x) + (self.y - y)*(self.y - y) < self.size*self.size then
		return true
	end
	return false
end



LIGHT_SOURCE.pixelcode =
[[
	number PI = 3.1415926535897932384626433832795;

	extern vec2 light_pos;
	extern number light_power;
	extern number light_radius;
	extern vec2 light_dir;
	extern vec4 blocks[64];
	extern number numBlocks;

	vec4 effect(vec4 color,Image texture,vec2 texture_coords, vec2 screen_coords)
	{
		number angle1 = atan(screen_coords.y - light_pos.y,screen_coords.x - light_pos.x);
		number dist = length(screen_coords - light_pos);
		number dir_angle = atan(light_dir.y,light_dir.x);
		number dlf = 0;
		bool draw = true;
		bool radial = (light_dir.x == 0 && light_dir.y == 0) ? true : false;
		
		for(int i = 0;i < numBlocks;i++){
			vec4 b = blocks[i];
			
			//angle between each of blocks corners
			number a1 = atan(b.y - light_pos.y,b.x - light_pos.x);			
			number a2 = atan(b.y + b.w - light_pos.y,b.x - light_pos.x);
			number a3 = atan(b.y - light_pos.y,b.x + b.z - light_pos.x);
			number a4 = atan(b.y + b.w - light_pos.y,b.x + b.z - light_pos.x);		

			//find min angle
			number mina = min(a1,a2);
			mina = min(mina,a3);
			mina = min(mina,a4);
			
			//find max angle
			number maxa = max(a1,a2);
			maxa = max(maxa,a3);
			maxa = max(maxa,a4);

			//find min x position and min y position
			number minx = min(abs(b.x - light_pos.x),abs(b.x + b.z - light_pos.x));
			number miny = min(abs(b.y - light_pos.y),abs(b.y + b.w - light_pos.y));

			//find whether the opposite sides of the box are in different coordinates relative to the light source
			bool xsign = sign(b.x - light_pos.x) == sign(b.x + b.z - light_pos.x);
			bool ysign = sign(b.y - light_pos.y) == sign(b.y + b.w - light_pos.y);			
			
			if(!xsign && !ysign){
				//box is right over top light source, ignore it
			}
			//SPECIAL CASE - box is straddling the angle 180/-180 line
			//both right and left side are on same side of the light source
			//top and bottom are on different sides of the light source
			//box is on left of light source, where the angles 180 and -180 are the same
			//coordinate we are drawing is to the left of the box (possibly in its shadow)
			else if(xsign 
					&& sign(b.y - light_pos.y) <= 0 && sign(b.y + b.w - light_pos.y) >= 0 
					&& sign(b.x - light_pos.x) < 0 
					&& abs(screen_coords.x - light_pos.x) >= minx){ 
				//if angle from light source to screen coords is between the angle of the bottom and top right box corners, don't draw anything
				if((angle1 >= a4 && angle1 <= PI) || (a1 != a3 && angle1 <= a3 && angle1 > -PI)){
					draw = false;
					break;
				}		
			}			
			else{
				//if angle is between the highest and lowest angle (the angle of the boxes corners that are casting shadows)
				if(angle1 >= mina && angle1 <= maxa){				
					//if boxes sides are all in the same quadrant and the screen coords we are looking at are in the shadow, don't draw anything
					if(xsign && ysign && abs(screen_coords.x - light_pos.x) >= minx && abs(screen_coords.y - light_pos.y) >= miny){
						draw = false;
						break;
					}
					// special case - box is above or below the light source, straddling the x = 0 line
					else if(!xsign && abs(screen_coords.y - light_pos.y) >= miny){
						draw = false;
						break;
					}
					// special case - box is on the right side of the light source, straddling the y = 0 line
					else if(!ysign && xsign
						&& sign(b.x - light_pos.x) > 0 && abs(screen_coords.x - light_pos.x) >= minx){
						draw = false;
						break;
					}
				}
			}
		}
		
		//if draw is true at this point, then this point isn't in shadow
		if(!radial && draw && dist < light_radius){
			if(distance(PI,dir_angle) < .01){
				if((angle1 > dir_angle - sin(PI*light_power/4) && angle1 < PI) || (angle1 < -PI + sin(PI*light_power/4) && angle1 > - PI)){
					dlf = 1 - dist/light_radius;
				}
			}else if(angle1 < dir_angle + sin(PI*light_power/4) && angle1 > dir_angle - sin(PI*light_power/4)){
				dlf = 1 - dist/light_radius;
			}
		}
		else if(radial && draw)			
			dlf = 1 - dist/light_radius;
		return Texel(texture,texture_coords) * dlf * color;
	}
]]

LIGHT_SOURCE.vertexcode =
[[		
	vec4 position(mat4 transform_projection,vec4 vertex_position)
	{			
		return transform_projection * vertex_position;
	}
]]

LIGHT_SOURCE.shader = love.graphics.newShader(LIGHT_SOURCE.pixelcode,LIGHT_SOURCE.vertexcode)