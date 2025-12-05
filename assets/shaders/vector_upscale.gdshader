shader_type canvas_item;

// https://godotshaders.com/shader/vector-sprite-upscaling-mix-colors/
// MIT

const int ML = 0;
uniform float THRESHOLD = 0.001;
uniform float AA_SCALE = 11.0;


bool eq(vec4 col1, vec4 col2) {
	vec4 dif = col1 - col2;
	float length_squared = dif.r * dif.r + dif.g * dif.g + dif.b * dif.b + dif.a * dif.a;
	return length_squared < THRESHOLD * THRESHOLD;
}


//draw diagonal line connecting 2 pixels if within threshold
vec4 diag(vec4 sum, vec2 uv, vec2 point1, vec2 point2, vec4 color1, vec4 color2, float LINE_THICKNESS) {
	if (eq(color1, color2)) {
		vec2 dir = point2 - point1;
		vec2 lp = uv - (floor(uv + point1)+.5);
		dir = normalize(vec2(dir.y, - dir.x));
		float l = clamp((LINE_THICKNESS - dot(lp, dir)) * AA_SCALE, 0.0, 1.0);
		sum = mix(sum, color1, l);
	}
	return sum;
}


void fragment()
{
	float LINE_THICKNESS = 0.4;
	vec2 ip = UV;
	ip = UV * (1.0 / TEXTURE_PIXEL_SIZE);
	
	/*
		lu	u	ru
		l	c	r
		ld	d	rd
	*/
	
	vec4 c = texelFetch(TEXTURE,ivec2(ip),ML);
	vec4 l = texelFetch(TEXTURE,ivec2(ip+vec2(-1,0)),ML);
	vec4 d = texelFetch(TEXTURE,ivec2(ip+vec2(0,1)),ML);
	vec4 r = texelFetch(TEXTURE,ivec2(ip+vec2(1,0)),ML);
	vec4 u = texelFetch(TEXTURE,ivec2(ip+vec2(0,-1)),ML);
		
	vec4 ld = texelFetch(TEXTURE,ivec2(ip+vec2(-1,1)),ML);
	vec4 lu = texelFetch(TEXTURE,ivec2(ip+vec2(-1,-1)),ML);
	vec4 rd = texelFetch(TEXTURE,ivec2(ip+vec2(1,1)),ML);
	vec4 ru = texelFetch(TEXTURE,ivec2(ip+vec2(1,-1)),ML);

	vec4 s = c;
	
	ivec4 mask = ivec4(1);

	if (eq(ld, c) ) mask.x = 0;
	if (eq(lu, c)) mask.y = 0;
	if (eq(rd, c)) mask.z = 0;
	if (eq(ru, c)) mask.w = 0;

	if (mask.x == 1) s = diag(s,ip,vec2(-1,0),vec2(0,1), l, d, LINE_THICKNESS);
	if (mask.y == 1) s = diag(s,ip,vec2(0,-1),vec2(-1,0), l, u, LINE_THICKNESS);
	if (mask.z == 1) s = diag(s,ip,vec2(0,1),vec2(1,0), r, d, LINE_THICKNESS);
	if (mask.w == 1) s = diag(s,ip,vec2(1,0),vec2(0,-1), r, u, LINE_THICKNESS);
		
	vec4 f = c;
	f = diag(f,ip,vec2(-1,0),vec2(0,1), l, d, LINE_THICKNESS);
	f = diag(f,ip,vec2(0,-1),vec2(-1,0), l, u, LINE_THICKNESS);
	f = diag(f,ip,vec2(0,1),vec2(1,0), r, d, LINE_THICKNESS);
	f = diag(f,ip,vec2(1,0),vec2(0,-1), r, u, LINE_THICKNESS);
	
	COLOR = (s+f) / 2.0;
}