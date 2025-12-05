shader_type canvas_item;

// https://godotshaders.com/shader/dotted-grid-2d/
// CC0

uniform float cell_size = 16;
uniform float dot_size : hint_range(0.0, 0.5) = 0.25;
uniform vec4 background_color : source_color = vec4(0.1176, 0.1176, 0.1176, 1.0);
uniform vec4 dot_color : source_color = vec4(0.2156, 0.2156, 0.2156, 1.0);
uniform vec2 resolution; // Resolution of the screen or viewport
uniform vec2 offset; // Offset to move the grid at runtime!
uniform float anti_aliasing_factor = 0.01; // Adjust this value for more/less smoothness
uniform int stochastic_samples = 16; // Number of stochastic samples per pixel

// Pseudo-random number generator function
float random(vec2 st){
	return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = FRAGCOORD.xy / resolution;
	vec4 finalColor = vec4(0.0);
	  
	for (int i = 0; i < stochastic_samples; ++i) {
		// Generate random offset within the pixel
		vec2 randomOffset = vec2(
			random(vec2(float(i), 0.0)),
			random(vec2(0.0, float(i)))
		) / resolution;
		
		// Apply offset and scale by cell_size
		vec2 scaled_pos = ((uv + randomOffset) * resolution + offset) / cell_size;
		
		// Find the nearest grid intersection in normalized space
		vec2 nearest_grid = round(scaled_pos) * cell_size;
		
		// Calculate the distance to the nearest grid intersection
		float dist = length(((uv + randomOffset) * resolution + offset) - nearest_grid);
		
		// Convert dot_size to an actual radius based on grid_size
		float radius = dot_size * cell_size * 0.5;
		
		// Anti-aliasing: Smooth transition near the edge of the dot
		float edge_smoothness = anti_aliasing_factor;
		float alpha = smoothstep(radius - edge_smoothness, radius + edge_smoothness, dist);
		
		// Mix dot_color and background_color based on alpha
		finalColor += mix(dot_color, background_color, alpha);
	}
	
	// Average the colors from all samples
	COLOR = finalColor / float(stochastic_samples);
}