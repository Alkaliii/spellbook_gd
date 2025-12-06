shader_type canvas_item;
render_mode unshaded, blend_mix;

// Procedural Idyllic Slash
// 💡 designed to produce slashes and sweeps
// 	 [*]|: https://github.com/Alkaliii/spellbook-gd

/*
	Copyright 2025 Ali
	
	Permission is hereby granted, free of charge, to any person obtaining a copy of 
	this software and associated documentation files (the “Software”), to deal in 
	the Software without restriction, including without limitation the rights to use, 
	copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the 
	Software, and to permit persons to whom the Software is furnished to do so, 
	subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all 
	copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// driver / easing profiles
// none, time, ease_in(cubic), ease_out(cubic), ease_in_out(cubic), ease_out_in(cubic), custom_a-f
// all profiles use RAW progress

uniform vec2 texture_size = vec2(1.0);

group_uniforms ANIMATION;
/**
	* This value animates the shader as it changes when [param derive_progress] == 1.
	* Modify it with an animation player or edit it from gdScript with:
	[code]material.set_shader_parameter("progress", new_value)[/code]
*/
uniform float progress : hint_range(0.0, 1.0, 0.001);

/**
	* Different ways to drive the shader's animation.
	* <0> [enum Time], Shader animates with global [constant TIME]
	* <1> [enum Progress], Shader animates with [param progress]
	* <2> [enum Lifetime], Shader animates with particle lifetime, [member INSTANCE_CUSTOM.y]
*/
uniform int derive_progress : hint_enum("Time","Progress","Lifetime") = 1;

/**
	* Different ways to interpolate the shader's animation.
	* <0> [enum Custom Ease], Use by setting a [CurveTexture] in [param custom_ease]
	* <1> [enum Ease In], Exponetial Ease In
	* <2> [enum Linear], Linear
	* <3> [enum Ease Out], Exponetial Ease Out
	* <4> [enum Ease In Out], Exponetial Ease In and Out
*/
uniform int ease_progress : hint_enum("Custom Ease","Ease In","Linear","Ease Out","Ease In Out") = 2;

/**
	* Set a [CurveTexture] here and change [param ease_progress] to 0.
	* The shader will sample the texture red channel to interpolate the animation.
*/
uniform sampler2D custom_ease : hint_default_white, filter_linear, repeat_disable;

/** Modifies animation length when [param derive_progress] == 1 */
uniform float time_scale : hint_range(0.0, 8.0, 0.01) = 1.0;

group_uniforms SHAPE;
uniform sampler2D mesh_wide_mask : source_color,hint_default_white;
uniform int apply_mwm: hint_enum("On Both","On ALPHA","on ALBEDO") = 0;
uniform float final_base_pow : hint_range(0.0, 8.0, 0.01) = 1.0;

group_uniforms SHAPE.ADJUSTMENTS;
uniform int polarize_uv : hint_enum("No", "Yes");
uniform vec4 polarize_settings = vec4(0.5,0.5,0.6,1.0);
// <center pos.x> <center pos.y> <zoom> <repeat>
uniform float polar_rot_deg = 0.0;
uniform vec2 fisheye_uv = vec2(0.0);
uniform vec4 fisheye_origin = vec4(0.5);
uniform int fisheye_uv_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;
uniform int fisheye_origin_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;

group_uniforms SHAPE.DISTORTION;
uniform int apply_distortion : hint_enum("No", "Yes");
uniform sampler2D distort_texture : source_color,hint_default_black,filter_linear,repeat_enable;
uniform float distort_str : hint_range(-3.0, 3.0, 0.1) = 0.3;
uniform float final_distort_str : hint_range(-3.0, 3.0, 0.1) = 0.3;
uniform vec4 scroll_distortion = vec4(0.0);
uniform vec4 scale_distortion = vec4(1.0);
uniform vec4 polarize_distortion = vec4(0.5,0.5,0.6,0.0);
// <center pos.x> <center pos.y> <zoom> <repeat>
uniform int distort_str_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;
uniform int distort_scroll_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;
uniform int distort_scale_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;
uniform bool index_shift_distortion = false;

group_uniforms SHAPE.BASE;
uniform int base_preset : hint_enum(
	"Custom","bsc Triangle","plr Wedge",
	"crt Trinity","plr Rhombus","bsc Square",
	"plr Taper","bsc Diamond","bsc Treble Star",
	"bsc Jax Treble Star","bsc Cross Star",
	"bsc Jax Cross Star","bsc Pentagram",
	"bsc Jax Pentagram") = 1;
uniform vec2[10] custom_poly_base;
uniform int custom_poly_base_point_count = 10;
uniform bool tweak_with_custom = false;
uniform float base_shape_size = 1.0;
uniform float base_rot_deg = 0.0;
uniform vec4 base_position_if = vec4(0.0);
uniform vec4 base_scale_if = vec4(vec2(1.0),vec2(1.0));
uniform int base_pos_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;
uniform int base_scale_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;

group_uniforms SHAPE.BASE_APPEARANCE;
uniform float base_feather = 0.0;
uniform int feather_falloff : hint_enum("Hermite","Pixiecubic","Exponential","Sigmoid²ˣ","Plateauhalo");
uniform vec3 feather_falloff_control = vec3(0.5);
uniform vec2 base_energy = vec2(1.0,1.0); // use this to fade out
uniform int base_energy_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;

group_uniforms SHAPE.BASE_MASK;
uniform sampler2D base_mask : source_color, hint_default_white, repeat_enable;
uniform int base_mask_control : hint_enum("Ignore", "Step", "Smoothstep") = 0;
uniform vec2 base_mask_pow = vec2(1.0);
uniform vec4 base_mask_edge = vec4(vec2(0.0,1.0),vec2(1.0));
uniform vec4 base_mask_scroll = vec4(0.0);
uniform vec4 base_mask_scale = vec4(1.0);
uniform int bm_pow_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;
uniform int bm_edge_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 2;
uniform int bm_scroll_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;
uniform int bm_scale_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;
uniform bool index_shift_mask = false;

group_uniforms SHAPE.BASE_MASK_AUTOGRAD;
uniform int bm_auto_grad : hint_enum("No","X","Y","Xin","Yin","XY","XYin","XinY","XinYin","Radial","Radial Inverse","Box","Box Inverse");
uniform vec4 bmag_edge = vec4(vec2(0.0,1.0),vec2(0.0,1.0));
uniform vec2 bmag_str = vec2(1.0);
uniform int bmag_str_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;
uniform int bmag_edge_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;

group_uniforms SHAPE.FOLLOWTHROUGH;
uniform int base_scale_anim : hint_enum("None","Xio","Xi","Xo","Yio","Yi","Yo");
uniform int base_scale_anim_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 2;

group_uniforms COLORIZE;
/**
	* Color the shader with gradient mapping!
	Set a [GradientTexture1D] here to sample from by gray value.
	By default the right-most color value will be used when [param shading] == 0
*/
uniform sampler2D color_gradient : source_color, hint_default_white, repeat_disable;


/**
	* This value will make the shader glow/darken.
	Works best when [member WorldEnvironment.Glow] is enabled.
*/
uniform float emission_intensity : hint_range(0.1, 16.0, 0.1) = 1.0;

/**
	* This value will posterize the shading resulting in value bands.
	A zero value will disable the calculation.
	A higher value will result in [i]less[/i] banding.
*/
uniform int chunky_color : hint_range(0, 100, 1) = 0;
uniform float tweak_alpha = 0.0;

group_uniforms COLORIZE.TWEAK_GRADIENT;
uniform vec2 shift_gradient = vec2(0.0);
uniform vec3 sample_edge_pow = vec3(0.0,1.0,1.0);
uniform int shift_gradient_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;

group_uniforms COLORIZE.GRADIENT_BIAS;
uniform int gradient_bias : hint_enum("No","X","Y","Xin","Yin","XY","XYin","XinY","XinYin","Radial","Radial Inverse","Box","Box Inverse");
uniform vec4 gbias_edge = vec4(vec2(0.0,1.0),vec2(0.0,1.0));
uniform vec2 gbias_str = vec2(1.0);
uniform vec2 gbias_shift = vec2(0.0);
uniform vec2 gbias_rot = vec2(0.0);
uniform int gb_edge_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;
uniform int gb_str_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;
uniform int gb_shift_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;
uniform int gb_rot_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;

group_uniforms COLORIZE.CHROMATIC_ABERRATION;
// Note: Very heavy on performance.

/**
	* Control how the shader applies a chromatic aberration effect to the image.
	Warn (!), Very heavy on performance! (For loops are increased by a factor of [param chroma_samples]/2.0])
	<0> [enum No], Shader will not apply chromatic aberration.
	<1> [enum Linear], Shader will apply effect in a linear fashion.
	<2> [enum Radial], Shader will apply effect in a radial manner.
	<3> [enum Twist], Shader will apply effect with a twist.
	
	* Chroma is based on example by XOR
	@source: [url]https://mini.gmshaders.com/p/gm-shaders-mini-chromatic-aberration[/url]
*/
uniform int apply_chroma : hint_enum("No", "Linear", "Radial", "Twist");

/** Number of samples used to produce chroma effect. (More samples results in a smoother effect) */
uniform int chroma_samples : hint_range(0, 10, 2);

/** Distance between samples in effect. */
uniform vec2 chroma_offset = vec2(0.01);

uniform int chroma_arrangement : hint_enum("rgb","rbg","grb","gbr","brg","bgr","rrb","rrg","ggr","ggb","bbr","bbg");
uniform float chroma_power = 2.0;
uniform vec4 tweak_chroma_weight = vec4(0.0);

group_uniforms vertex;

uniform vec2 rescale_vertex = vec2(1.0);

/** Offset the mesh from it's center point. */
uniform vec2 mesh_offset = vec2(0.0);

/** Offset the mesh from it's center point, when interpolation is 'finished'. */
uniform vec2 final_mesh_offset = vec2(0.0);

uniform int mesh_offset_driver : hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
"prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D") = 0;

/** Randomly rotate mesh using particle index, [member INSTANCE_ID]. */
uniform float index_rand_mesh_rot = 0.0;

/** math stuff. [param index_rand_mesh_rot] will function differently. */
uniform bool maintain_irm_domain = false;

/** Rotate the mesh the shader is applied to in XYZ axis by the specified amount in degrees. */
uniform float mesh_rotation = 0.0;

/** Speed mesh will rotate with on axis. */
uniform float animate_mesh_rotation = 0.0;

/**
	* Control how the shader drives rotation.
	<0> [enum Nothing], Shader will not interpolate.
	<1> [enum Time], Shader will drive using global time, [constant TIME].
	<2> [enum Progress], Shader will drive using progress, [param progress].
*/
uniform int animate_mesh_rot_with : hint_enum("Nothing", "Time", "Progress") = 0;

group_uniforms vertex.PERSPECTIVE;
// Shamelessly stolen implementation
// Original by codevogel
// https://godotshaders.com/shader/faux-3d-perspective-shader-for-2d-canvas-items/
uniform bool cull_backface = false;
uniform float fov : hint_range(1, 179) = 1.0;
uniform float rot_y_deg : hint_range(-360, 360) = 0.0;
uniform float rot_x_deg : hint_range(-360, 360) = 0.0;
uniform float inset : hint_range(0, 1) = 0.0;

varying vec2 vp_offset;
varying vec3 world_pos_3d;

group_uniforms CURVES;
uniform sampler2D custom_a : hint_default_black, filter_linear, repeat_disable;
uniform sampler2D custom_b : hint_default_black, filter_linear, repeat_disable;
uniform sampler2D custom_c : hint_default_black, filter_linear, repeat_disable;
uniform sampler2D custom_d : hint_default_black, filter_linear, repeat_disable;

group_uniforms RANDOM;
/**
	* Control how the shader produces random values.
	<0> [enum BoSh] fract(sin(dot())) as described in the Book of Shaders
	@tutorial: [url]https://thebookofshaders.com/10/[/url]
	<1> [enum Sinless] fract() & dot() then fract(), an implementation by Dave Hoskins.
	@source: [url]https://www.shadertoy.com/view/4djSRWp[/url]
*/
uniform int randomness : hint_enum("BoSh", "Sinless") = 0;

/** Offset the randomness, the possibilities are finte, but varied! */
uniform int randomness_seed = 0;

/** Offset the randomness using particle index, [member INSTANCE_ID]. */
uniform int index_shift_randomness : hint_enum("No", "Yes") = 0;

group_uniforms DEBUG;
// you need to uncomment some stuff to use this
uniform bool disable_mask = false;
uniform bool disable_colorize = false;
uniform bool disable_transparency = false;
uniform int isolate_base : hint_enum("No", "Modified", "Basic");
// pow step
//uniform vec2 smoothstep_base = vec2(0.0,1.0);

//group_uniforms SHAPE_HIGHLIGHT;
//uniform int highlight_shape_sides = 3;
//uniform float highlight_shape_size = 0.3;
//uniform float highlight_rot_deg = 0.0;
//uniform vec2 highlight_scale = vec2(1.0);
//uniform float highlight_feather = 0.0;
//uniform float highlight_shape_cut : hint_range(-1.0, 1.0, 1.0);
//uniform sampler2D highlight_alpha_mask : source_color, hint_default_white;

const float EPSILON = 0.00001;
const int pN = 10; //polygon point count
const vec2[pN] cleanArr = {
	vec2(0.0),vec2(0.0),vec2(0.0),vec2(0.0),vec2(0.0),
	vec2(0.0),vec2(0.0),vec2(0.0),vec2(0.0),vec2(0.0)
};

varying float LIFETIME;
varying float INDEX;
varying flat int PARTICLE;
varying float[11] CHRONOGRAPH;

struct shapedat {
	vec2[pN] points;
	int maxi; // max iteration
};

// create shape
// optional secondary shape (copy of primary with offset / scale)
// can alpha mask it with noise + optional gradient
// can albedo mask and smoothstep it
// move it across UV
// optional polar UV

float random(vec2 uv) {
	// provides a random number given a vec2
	// seed setup sucks lol
	float seed = float(randomness_seed) / PI;
	if (index_shift_randomness == 1) {seed += float(PARTICLE);}
	switch (randomness) {
		case 0:
			return fract(sin(dot(uv.xy,vec2(12.9898 + seed,78.233))) * 43758.5453123 + seed);
		case 1:
			// https://www.shadertoy.com/view/4djSRW
			vec3 p3  = fract(vec3(uv.xyx + seed) * .1031);
			p3 += dot(p3, p3.yzx + 33.33);
			return fract((p3.x + p3.y) * p3.z + seed);
	}
}

float grayscale(vec3 rgb, int type) {
	// average
	if (type == 1) {
		return (rgb.r + rgb.g + rgb.b) / 3.0;
	}
	// weighted
	const float rw = 0.299;
	const float gw = 0.587;
	const float bw = 0.114;
	rgb *= vec3(rw,gw,bw);
	return rgb.r + rgb.g + rgb.b;
}

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - dot(normalize(normal), normalize(view))), amount);
}

vec2 polar_coordinates(vec2 uv, vec2 center, float zoom, float repeat) {
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) * 1.0/(3.1416 * 2.0);
	return mod(vec2(radius * zoom, angle * repeat), 1.0);
}

vec2 spherize(vec2 uv, vec2 center, float strength, vec2 offset) {
	// https://godotshaders.com/shader/uv-spherize/
	// Вектор от центра искажения к текущим UV
	vec2 delta = uv - center;
	// Квадрат длины вектора delta (эквивалент length(delta)^2)
	float delta2 = dot(delta.xy, delta.xy);
	// delta4 — четвёртая степень расстояния (усиливает искажение ближе к краям)
	float delta4 = delta2 * delta2;
	// Смещение вектора delta в зависимости от delta4 и силы
	vec2 delta_offset = vec2(delta4, delta4) * strength;
	// Добавляем искажение и смещение
	return uv + (delta * delta_offset) + offset;
}

float easeOutExpo(float x) {
	return 1.0 - pow(2.0, -10.0 * x);
}

float easeInExpo(float x) {
	return pow(2.0, 10.0 * x - 10.0);
}

float easeInOutExpo(float x) {
	float result;
	if (x == 0.0) {result = 0.0;}
	else if (x == 1.0) {result = 1.0;}
	else if (x < 0.5) {result = pow(2.0, 20.0 * x - 10.0) / 2.0;}
	else {result = (2.0 - pow(2.0, -20.0 * x + 10.0)) / 2.0;}
	return result;
}

float easeInCubic(float x) {
	return x * x * x;
}

float easeOutCubic(float x) {
	return 1.0 - pow(1.0 - x,3.0);
}

float easeInOutCubic(float x) {
	return x < 0.5 ? 4.0 * x * x * x : 1.0 - pow(-2.0 * x + 2.0,3.0) / 2.0;
}

float easeOutInCubic(float x) {
	return (4.0 * pow(x-0.5,3.0)) + 0.5;
}

vec2 scale(vec2 uv, float x, float y, vec2 from) {
	mat2 scale = mat2(vec2(x, 0.0), vec2(0.0, y));
	//uv -= 0.5;
	uv -= from;
	uv = uv * scale;
	//uv += 0.5;
	uv += from;
	return uv;
}

vec2 rotate(vec2 uv, vec2 pivot, float angle) {
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						vec2(cos(angle), sin(angle)));
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}

mat3 rotateX(float theta) {
	float cosa = cos(theta);
	float sina = sin(theta);

	mat3 rotate_x  = mat3(
	   vec3(1.0, 0.0, 0.0),
	   vec3(0.0, cosa, -sina),
	   vec3(0.0, sina, cosa)
	);
	return rotate_x;
}

mat3 rotateY(float theta) {
	float cosa = cos(theta);
	float sina = sin(theta);

	mat3 rotate_y  = mat3(
	   vec3(cosa, 0.0, sina),
	   vec3(0.0, 1.0, 0.0),
	   vec3(-sina, 0.0, cosa)
	);
	return rotate_y;
}

mat3 rotateZ(float theta) {
	float cosa = cos(theta);
	float sina = sin(theta);

	mat3 rotate_z  = mat3(
	   vec3(cosa,-sina, 0.0),
	   vec3(sina, cosa, 0.0),
	   vec3(0.0, 0.0, 1.0)
	);
	return rotate_z;
}

float uv2mask(vec2 uv, int type, float power, vec2 edge) {
	// generates a mask using UV;
	uv = smoothstep(edge.x,edge.y,uv);
	float mask = 1.0;
	switch (type) {
		case 0: return mask;
		case 1: mask = uv.x; break;
		case 2: mask = uv.y; break;
		case 3: mask = 1.0-uv.x; break;
		case 4: mask = 1.0-uv.y; break;
		case 5: mask = ((uv.x) + (uv.y)) / 2.0; break;
		case 6: mask = ((uv.x) + (1.0-uv.y)) / 2.0; break;
		case 7: mask = ((1.0-uv.x) + (uv.y)) / 2.0; break;
		case 8: mask = ((1.0-uv.x) + (1.0-uv.y)) / 2.0; break;
		case 9: mask = length(uv-0.5); break;
		case 10: mask = 1.0-length(uv-0.5); break;
		case 11:
			uv = rotate(uv,vec2(0.5),radians(45.0));
			mask = 1.0-((1.0-length(uv.y-0.5)) * (1.0-length(uv.x-0.5))); break;
		case 12:
			uv = rotate(uv,vec2(0.5),radians(45.0));
			mask = (1.0-length(uv.y-0.5)) * (1.0-length(uv.x-0.5)); break;
	}
	mask = clamp(pow(mask,power),0.0,1.0);
	return mask;
}

float shapestep(int type, float edge0, float edge1, float x, vec3 control) {
	// 0 Smoothstep
	// 1 Double-Cubic Seat : http://www.flong.com/archive/texts/code/shapers_poly/
	// 2 Exponetial In/Out : http://www.flong.com/archive/texts/code/shapers_exp/
	// 3 Double Exponetial Sigmoid : http://www.flong.com/archive/texts/code/shapers_exp/
	// 4 Double-Odd-Polynomial Seat : http://www.flong.com/archive/texts/code/shapers_poly/
	
	float mina = 0.0 + EPSILON;
	float maxa = 1.0 - EPSILON;
	float minb = 0.0;
	float maxb = 1.0;
	float a = min(maxa,max(mina,control.x));
	float b = min(maxb,max(minb,control.y));
	float y = 0.0;
	
	if (type != 0) {x = clamp((x - edge0) / (edge1 - edge0),0.0,1.0);}
	
	switch (type) {
		case 1: // 1 Double-Cubic Seat
			if (x <= a) {y = b-b*pow(1.0-x/a,3.0);}
			else {y = b + (1.0-b)*pow((x-a)/(1.0-a),3.0);}
			return y;
		case 2: // 2 Exponetial In/Out
			if (a < 0.5) {
				a = 2.0*a;
				y = pow(x,a);
			} else {
				a = 2.0*(a-0.5);
				y = pow(x,1.0/(1.0-a));
			}
			return y;
		case 3: // 3 Double Exponetial Sigmoid
			a = 1.0-a;
			if (x<0.5) {y = (pow(2.0*x,1.0/a))/2.0;}
			else {y = 1.0 - (pow(2.0*(1.0-x),1.0/a))/2.0;}
			return y;
		case 4: // 4 Double-Odd-Polynomial Seat
			float p = 2.0*ceil(control.z)+1.0;
			if (x <= a) {y = b - b*pow(1.0-x/a,p);}
			else {y = b + (1.0-b)*pow((x-a)/(1.0-a),p);}
			return y;
		default: return smoothstep(edge0,edge1,x);
	}
	return y;
}

float polygon(vec2 uv, vec2 v[pN], int maxi, float feather) {
	uv -= 0.5;
	float d = dot(uv-v[0],uv-v[0]);
	float s = 1.0;
	//int N = v.length();
	for( int i=0, j=maxi-1; i<maxi; j=i, i++ ) {
		vec2 e = v[j] - v[i];
		vec2 w = uv - v[i];
		vec2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
		d = min( d, dot(b,b) );
		bvec3 c = bvec3(uv.y>=v[i].y,uv.y<v[j].y,e.x*w.y>e.y*w.x);
		if( all(c) || all(not(c)) ) s*=-1.0;
	}
	float p = shapestep(feather_falloff,0.0,feather,s*sqrt(d),feather_falloff_control); //smoothstep(0.0,feather,s*sqrt(d));
	if (feather < 0.0) {
		return 1.0-p;
	} return p;
}

float get_progress() {
	float p;
	float final;
	if (derive_progress == 2) {p = LIFETIME;}
	else if (derive_progress == 0) {p = mod(TIME * time_scale,1.0);}
	// abs(sin(TIME * time_scale)) [Back and Forth]
	// mod(TIME * time_scale,1.0) [Over and Over]
	else {p = progress;}

	if (ease_progress == 4) {final = easeInOutExpo(p);} //EASE IN OUT (2.0)
	else if (ease_progress == 0) {final = texture(custom_ease,vec2(p,0.0)).r;} //CUSTOM EASE (-2.0)
	else if (ease_progress == 3) {final = 1.0 - pow(2.0, -10.0 * p);} //EASE OUT (1.0)
	else if (ease_progress == 1) {final = pow(2.0, 10.0 * p - 10.0);} //EASE IN (-1.0)
	else {final = p;}

	return final;
}

float feed_chrono() {
	float p;
	if (derive_progress == 2) {p = LIFETIME;}
	else if (derive_progress == 0) {p = mod(TIME * time_scale,1.0);}
	// abs(sin(TIME * time_scale)) [Back and Forth]
	// mod(TIME * time_scale,1.0) [Over and Over]
	else {p = progress;}
	
	return p;
}

void vertex() {
	// Called for every vertex the material is visible on.
	LIFETIME = INSTANCE_CUSTOM.y;
	INDEX = float(INSTANCE_ID);
	PARTICLE = int(INDEX);
	
	// hint_enum("None","Time","Progress","prg Ease In","prg Ease Out",
	// "prg Ease In Out","prg Ease Out In","prg Custom A","prg Custom B","prg Custom C","prg Custom D");
	
	float fc = feed_chrono();
	CHRONOGRAPH[0] = 0.0;
	CHRONOGRAPH[1] = TIME;
	CHRONOGRAPH[2] = get_progress();
	CHRONOGRAPH[3] = easeInCubic(fc);
	CHRONOGRAPH[4] = easeOutCubic(fc);
	CHRONOGRAPH[5] = easeInOutCubic(fc);
	CHRONOGRAPH[6] = easeOutInCubic(fc);
	CHRONOGRAPH[7] = texture(custom_a,vec2(fc,0.0)).r;
	CHRONOGRAPH[8] = texture(custom_b,vec2(fc,0.0)).r;
	CHRONOGRAPH[9] = texture(custom_c,vec2(fc,0.0)).r;
	CHRONOGRAPH[10] = texture(custom_d,vec2(fc,0.0)).r;
	
	float r = random(vec2(float(PARTICLE)));
	float r2 = (random(vec2(float(PARTICLE))) - 0.5) * 2.0;
	
	vec2 tv = VERTEX - vec2(0.5) * texture_size;
	tv *= rescale_vertex;
	VERTEX = tv + vec2(0.5) * texture_size;
	VERTEX += mix(mesh_offset,final_mesh_offset,CHRONOGRAPH[mesh_offset_driver]);
	
	float rot_rand = radians(index_rand_mesh_rot) * r2;
	if (maintain_irm_domain) { rot_rand = radians(index_rand_mesh_rot) * r;}
	float rotation_offset = radians(mesh_rotation) + (animate_mesh_rotation * CHRONOGRAPH[animate_mesh_rot_with]) + rot_rand;
	
	//mat3 rotation_matrix = rotateX(rotation_offset.x) * rotateY(rotation_offset.y) * rotateZ(rotation_offset.z);
	vec2 pos = VERTEX - vec2(0.5) * texture_size;
	mat2 rotation_matrix = mat2(vec2(cos(rotation_offset),-sin(rotation_offset)),vec2(sin(rotation_offset),cos(rotation_offset)));
	pos = rotation_matrix * pos;
	VERTEX = pos + vec2(0.5) * texture_size;
	
	// PERSPECTIVE
	float rot_y_rad = radians(rot_y_deg);
	float rot_x_rad = radians(rot_x_deg);

	float sin_y = sin(rot_y_rad), cos_y = cos(rot_y_rad);
	float sin_x = sin(rot_x_rad), cos_x = cos(rot_x_rad);

	// Construct rotation matrix
	mat3 rotation_matrix3d;
	rotation_matrix3d[0] = vec3(cos_y, 0.0, -sin_y);
	rotation_matrix3d[1] = vec3(sin_y * sin_x, cos_x, cos_y * sin_x);
	rotation_matrix3d[2] = vec3(sin_y * cos_x, -sin_x, cos_y * cos_x);

	// Project UV coordinates into pseudo-3D space
	float perspective_scale = tan(radians(fov) * 0.5);
	world_pos_3d = rotation_matrix3d * vec3(UV - 0.5, 0.5 / perspective_scale);

	// Adjust XY coordinates based on perspective depth
	float depth_scale = (0.5 / perspective_scale) + 0.5;
	world_pos_3d.xy *= depth_scale * rotation_matrix3d[2].z;
	vp_offset = depth_scale * rotation_matrix3d[2].xy;

	// Apply perspective transformation to vertex position 
	VERTEX += (UV - 0.5) / TEXTURE_PIXEL_SIZE * perspective_scale * (1.0 - inset);
}

//float get_eased_valuef(sampler2D ease, float init, float final) {
	//float sample = texture(ease,vec2(get_progress(),0.0)).r;
	//return mix(init,final,sample);
//}

//vec2 get_eased_valuev2(sampler2D ease, vec2 init, vec2 final) {
	//float sample = texture(ease,vec2(get_progress(),0.0)).r;
	//return mix(init,final,sample);
//}

//vec3 get_eased_valuev3(sampler2D ease, vec3 init, vec3 final) {
	//float sample = texture(ease,vec2(get_progress(),0.0)).r;
	//return mix(init,final,sample);
//}

//vec4 get_eased_valuev4(sampler2D ease, vec4 init, vec4 final) {
	//float sample = texture(ease,vec2(get_progress(),0.0)).r;
	//return mix(init,final,sample);
//}

shapedat get_shape_preset(int preset) {
	shapedat sd;
	switch (preset) {
		case 0:
			sd.points = custom_poly_base;
			sd.maxi = custom_poly_base_point_count;
			break;
		case 1:
			// Basic Triangle
			sd.points = cleanArr;
			sd.points[0] = vec2(0.5,-0.5);
			sd.points[1] = vec2(0.5);
			sd.points[2] = vec2(-0.5,0.5);
			sd.maxi = 3;
			break;
		case 2:
			// plr Wedge
			// Use this to quickly produce a cyclic slash (polar coords on a quad)
			sd.points = cleanArr;
			sd.points[0] = vec2(-0.05,-0.5);
			sd.points[1] = vec2(-0.05,0.4);
			sd.points[2] = vec2(0.0,0.3);
			sd.maxi = 3;
			break;
		case 3:
			// crt Trinity
			// Use this to quickly produce a normal slash on a mesh (cartesian coords on any mesh)
			sd.points = cleanArr;
			sd.points[0] = vec2(0.5,-0.5);
			sd.points[1] = vec2(0.5);
			sd.points[2] = vec2(-0.5,-0.5);
			sd.maxi = 3;
			break;
		case 4:
			// plr Rhombius
			sd.points = cleanArr;
			sd.points[0] = vec2(-0.025,-0.5);
			sd.points[1] = vec2(0.0,0.3);
			sd.points[2] = vec2(-0.025,0.35);
			sd.points[3] = vec2(-0.05,0.3);
			sd.maxi = 4;
			break;
		case 5:
			// Basic Square
			sd.points = cleanArr;
			sd.points[0] = vec2(0.5,-0.5);
			sd.points[1] = vec2(0.5);
			sd.points[2] = vec2(-0.5,0.5);
			sd.points[3] = vec2(-0.5);
			sd.maxi = 4;
			break;
		case 6:
			// plr Taper
			sd.points = cleanArr;
			sd.points[0] = vec2(-0.05,-0.5);
			sd.points[1] = vec2(-0.05,0.4);
			sd.points[2] = vec2(-0.15,0.4);
			sd.maxi = 3;
			break;
		case 7:
			// Basic Diamond
			sd.points = cleanArr;
			sd.points[0] = vec2(0.0,-0.5);
			sd.points[1] = vec2(0.5,0.0);
			sd.points[2] = vec2(0.0,0.5);
			sd.points[3] = vec2(-0.5,0.0);
			sd.maxi = 4;
			break;
		case 8:
			// Basic Treble Star (ir: 0.2) *Claude Sonnet 4.5, 2025
			sd.points = cleanArr;
			sd.points[0] = vec2(0.5,0.0);
			sd.points[1] = vec2(0.1,0.173);
			sd.points[2] = vec2(-0.25,0.433);
			sd.points[3] = vec2(-0.2,0.0);
			sd.points[4] = vec2(-0.25,-0.433);
			sd.points[5] = vec2(0.1,-0.173);
			sd.maxi = 6;
			break;
		case 9:
			// Basic Jax Treble Star (ir: 0.05) *Claude Sonnet 4.5, 2025
			sd.points = cleanArr;
			sd.points[0] = vec2(0.5,0.0);
			sd.points[1] = vec2(0.025,0.043);
			sd.points[2] = vec2(-0.25,0.433);
			sd.points[3] = vec2(-0.05,0.0);
			sd.points[4] = vec2(-0.25,-0.433);
			sd.points[5] = vec2(0.025,-0.043);
			sd.maxi = 6;
			break;
		case 10:
			// Basic Cross Star (ir: 0.2) *Claude Sonnet 4.5, 2025
			sd.points = cleanArr;
			sd.points[0] = vec2(0.5,0.0);
			sd.points[1] = vec2(0.141);
			sd.points[2] = vec2(0.0,0.5);
			sd.points[3] = vec2(-0.141,0.141);
			sd.points[4] = vec2(-0.5,0.0);
			sd.points[5] = vec2(-0.141);
			sd.points[6] = vec2(0.0,-0.5);
			sd.points[7] = vec2(0.141,-0.141);
			sd.maxi = 8;
			break;
		case 11:
			// Basic Jax Cross Star (ir: 0.05) *Claude Sonnet 4.5, 2025
			sd.points = cleanArr;
			sd.points[0] = vec2(0.5,0.0);
			sd.points[1] = vec2(0.035);
			sd.points[2] = vec2(0.0,0.5);
			sd.points[3] = vec2(-0.035,0.035);
			sd.points[4] = vec2(-0.5,0.0);
			sd.points[5] = vec2(-0.035);
			sd.points[6] = vec2(0.0,-0.5);
			sd.points[7] = vec2(0.035,-0.035);
			sd.maxi = 8;
			break;
		case 12:
			// Basic Pentagram (ir: 0.2) *Claude Sonnet 4.5, 2025
			sd.points = cleanArr;
			sd.points[0] = vec2(0.5,0.0);
			sd.points[1] = vec2(0.162,0.118);
			sd.points[2] = vec2(0.154,0.476);
			sd.points[3] = vec2(-0.062,0.190);
			sd.points[4] = vec2(-0.405,0.294);
			sd.points[5] = vec2(-0.200,0.0);
			sd.points[6] = vec2(-0.405,-0.294);
			sd.points[7] = vec2(-0.062,-0.190);
			sd.points[8] = vec2(0.154,-0.476);
			sd.points[9] = vec2(0.162,-0.118);
			sd.maxi = 10;
			break;
		case 13:
			// Basic Jax Pentagram (ir: 0.05) *Claude Sonnet 4.5, 2025
			sd.points = cleanArr;
			sd.points[0] = vec2(0.5,0.0);
			sd.points[1] = vec2(0.040,0.029);
			sd.points[2] = vec2(0.154,0.476);
			sd.points[3] = vec2(-0.015,0.048);
			sd.points[4] = vec2(-0.405,0.294);
			sd.points[5] = vec2(-0.050,0.0);
			sd.points[6] = vec2(-0.405,-0.294);
			sd.points[7] = vec2(-0.015,-0.048);
			sd.points[8] = vec2(0.154,-0.476);
			sd.points[9] = vec2(0.040,-0.029);
			sd.maxi = 10;
			break;
	}
	return sd;
}

float cos_wve(float x) {
	return -cos(x*2.*PI)*.5+.5;
}

float lin_cos_wve(float x) {
	return (2./PI) * asin(-cos(x*2.*PI))*.5+.5;
}

vec2 scale_anim(vec2 uv, int preset, float prg) {
	vec2 nuv = uv;
	vec2 from = vec2(0.0);
	// normal wave = -cos(x*2.*PI)*.5+.5
	// linear wave = (2./PI) * asin(-cos(x*2.*PI))*.5+.5
	if (prg >= 0.5) {from = vec2(1.0);}
	switch (preset) {
		case 0: return nuv;
		case 1:
			float s = max(cos_wve(prg),1./4096.);
			nuv = scale(nuv,1.0/s,1.0,from); break;
		case 2:
			float s = max(cos_wve(min(prg,0.5)),1./4096.);
			nuv = scale(nuv,1.0/s,1.0,from); break;
		case 3:
			float s = max(cos_wve(max(prg,0.5)),1./4096.);
			nuv = scale(nuv,1.0/s,1.0,from); break;
		case 4:
			float s = max(cos_wve(prg),1./4096.);
			nuv = scale(nuv,1.0,1.0/s,from); break;
		case 5:
			float s = max(cos_wve(min(prg,0.5)),1./4096.);
			nuv = scale(nuv,1.0,1.0/s,from); break;
		case 6:
			float s = max(cos_wve(max(prg,0.5)),1./4096.);
			nuv = scale(nuv,1.0,1.0/s,from); break;
	}
	return nuv;
}


float create_base_image(vec2 uv,float prg,int edge_control) {
	vec2 baseUV = uv - mix(base_position_if.xy,base_position_if.zw,CHRONOGRAPH[base_pos_driver]);
	vec2 base_scale = 1.0/mix(base_scale_if.xy,base_scale_if.zw,CHRONOGRAPH[base_scale_driver]);
	//vec2 highUV = (aUV - highlight_inital_position);
	float r3 = (random(vec2(float(PARTICLE),float(-PARTICLE))) - 0.5) * 2.0;
	float r4 = (random(vec2(float(-PARTICLE),float(PARTICLE))) - 0.5) * 2.0;
	vec2 is = vec2(0.0);
		if (index_shift_mask) {
			is = vec2(r4,r3);
		}

	shapedat bsd = get_shape_preset(base_preset);
	vec2[pN] pbArr = bsd.points;
	for (int i = 0; i < pN; i++) { //resize
		pbArr[i] = pbArr[i] * base_shape_size;
		if (tweak_with_custom) {pbArr[i] += custom_poly_base[i];}
	}
	float polyBase = 1.0 - polygon(
		rotate(
			scale_anim(scale(baseUV,base_scale.x,base_scale.y,vec2(0.5)),base_scale_anim,CHRONOGRAPH[base_scale_anim_driver]),
			vec2(0.5),radians(base_rot_deg) + radians(90.)),
			pbArr, bsd.maxi,
			base_feather);

	/** UNCOMMENT FOR DEBUG */
	switch (isolate_base) {
		case 1:
			polyBase = 1.0 - polygon(
				rotate(
					scale(baseUV,1.0/base_scale_if.x,1.0/base_scale_if.y,vec2(0.5)),
					vec2(0.5),
					radians(base_rot_deg) + radians(90.)),
					pbArr,bsd.maxi,base_feather
				);
			return polyBase;
		case 2:
			polyBase = 1.0 - polygon(
				scale(
					baseUV + mix(base_position_if.xy,base_position_if.zw,CHRONOGRAPH[base_pos_driver]),
					base_shape_size/0.3, base_shape_size/0.3, vec2(0.5)
				),
				pbArr,bsd.maxi,0.0
			);
			return polyBase;
		default: break;
	}
	// DEBUG ^^^
	
	float bmsk;
	vec2 bmuv = baseUV;
	//scroll
	if (bm_scroll_driver == 1) {
		bmuv += base_mask_scroll.xy * TIME;
	} else {
		bmuv += mix(base_mask_scroll.xy,base_mask_scroll.zw,CHRONOGRAPH[bm_scroll_driver]) * vec2(prg);
	}
	//scale
	vec2 bmuvsf = mix(base_mask_scale.xy,base_mask_scale.zw,CHRONOGRAPH[bm_scale_driver]);
	bmuv = scale(bmuv,1.0/bmuvsf.x,1.0/bmuvsf.y,vec2(0.5));
	float bmags = mix(bmag_str.x,bmag_str.y,CHRONOGRAPH[bmag_str_driver]);
	float bmskp = mix(base_mask_pow.x,base_mask_pow.y,CHRONOGRAPH[bm_pow_driver]);
	float bmskr = texture(base_mask,bmuv + is).r;
	vec2 agUV = clamp(bmuv,0.0,1.0);
	bmskr *= uv2mask(agUV,bm_auto_grad,bmags,
	mix(bmag_edge.xy,bmag_edge.zw,CHRONOGRAPH[bmag_edge_driver])
	);
	//switch (bm_auto_grad) {
		//case 1: bmskr *= pow(agUV.x,bmags); break;
		//case 2: bmskr *= pow(agUV.y,bmags); break;
		//case 3: bmskr *= pow(1.0-agUV.x,bmags); break;
		//case 4: bmskr *= pow(1.0-agUV.y,bmags); break;
		//case 5: bmskr *= pow((agUV.x+agUV.y)/2.0,bmags); break;
		//case 6: bmskr *= pow(((1.0-agUV.x)+agUV.y)/2.0,bmags); break;
		//case 7: bmskr *= pow((agUV.x+(1.0-agUV.y))/2.0,bmags); break;
		//case 8: bmskr *= pow(1.0-(agUV.x+agUV.y)/2.0,bmags); break;
		//default: break;
	//}
	//bmskr -= pow(1.0-mod(abs(uv.x+0.5),1.0),8.0); //you can use UV.x to create a hard edge but it's kinda meh.
	switch (edge_control) {
		case 1:
			float edge = mix(base_mask_edge.x,base_mask_edge.z,CHRONOGRAPH[bm_edge_driver]);
			bmsk = step(edge,pow(bmskr,bmskp));
			break;
		case 2:
			vec2 edge = mix(base_mask_edge.xy,base_mask_edge.zw,CHRONOGRAPH[bm_edge_driver]);
			bmsk = smoothstep(edge.x,edge.y,pow(bmskr,bmskp));
			break;
		default: bmsk = bmskr; break;
	}
	polyBase *= pow(bmsk,final_base_pow);

	/** UNCOMMENT FOR DEBUG */
	if (disable_mask == true) {
		polyBase /= pow(bmsk,final_base_pow);
	}
	// DEBUG ^^^

	return polyBase;
}

vec4 chroma_rearrange(int r, vec4 o) {
	// "rgb","rbg","grb","gbr","brg","bgr","rrb","rrg","ggr","ggb","bbr","bbg"
	switch (r) {
		case 0: 	return o.rgba;
		case 1: 	return o.rbga;
		case 2: 	return o.grba;
		case 3: 	return o.gbra;
		case 4: 	return o.brga;
		case 5: 	return o.bgra;
		case 6: 	return o.raba;
		case 7: 	return o.raga;
		case 8: 	return o.gara;
		case 9: 	return o.gaba;
		case 10: 	return o.bara;
		case 11: 	return o.baga;
	}
}

vec4 create_base_splits(vec2 uv,float prg,int edge_control) {
	// Chromatic Aberration
	// Super bad for performance lol and not that cool honestly due to how alpha works in this shader...
	// https://mini.gmshaders.com/p/gm-shaders-mini-chromatic-aberration
	vec4 chroma_sum = vec4(0.0);
	vec4 weight_sum = vec4(0.0);
	vec2 chroma_uv = uv;//scale(uv,0.01,0.01)-0.5;
	for (float i = 0.0; i <= 1.0; i += 1.0/float(chroma_samples)) {
		vec2 ca_uv;
		switch (apply_chroma) {
			case 1: ca_uv = chroma_uv + (i-0.5) * chroma_offset; break;
			case 2: ca_uv = mix(chroma_uv,vec2(0.5),(i-0.5) * chroma_offset); break;
			case 3: ca_uv = chroma_uv + vec2(chroma_uv.y-0.5,0.5-chroma_uv.x) * (i-0.5) * chroma_offset; break;
		}
		vec4 ca_color = vec4(create_base_image(ca_uv,prg,edge_control));
		vec4 ca_weight = vec4(
			i, //R
			1.0-abs(i*2.0-1.0), //G
			1.0-i, //B
			0.5 //A
		) + (tweak_chroma_weight);
		ca_weight = pow(chroma_rearrange(chroma_arrangement,ca_weight),vec4(abs(chroma_power)));
		chroma_sum += ca_color * ca_color * ca_weight;
		weight_sum += ca_weight;
	}
	//weight_sum *= 2.0;
	vec4 chroma_split = sqrt(chroma_sum/weight_sum);
	//col = grayscale(chroma_split.rgb,0);
	return clamp(chroma_split,-1.0,1.0);
}

void fragment() {
	// Called for every pixel the material is visible on.
	if (cull_backface && world_pos_3d.z <= 0.0) discard;
	vec2 projected_uv = (world_pos_3d.xy / world_pos_3d.z) - vp_offset + 0.5;
	if (projected_uv.x < 0.0 || projected_uv.x > 1.0 || projected_uv.y < 0.0 || projected_uv.y > 1.0)
		discard;
	
	float prg = get_progress();
	float r1 = (random(vec2(float(PARTICLE))) - 0.5) * 2.0;
	float r2 = (random(vec2(float(-PARTICLE))) - 0.5) * 2.0;
	float r3 = (random(vec2(float(PARTICLE),float(-PARTICLE))) - 0.5) * 2.0;
	float r4 = (random(vec2(float(-PARTICLE),float(PARTICLE))) - 0.5) * 2.0;
	
	vec2 uv = projected_uv;
	if (isolate_base == 0) {
		uv = spherize(projected_uv,
			mix(fisheye_origin.xy,fisheye_origin.zw,CHRONOGRAPH[fisheye_origin_driver])
			,mix(fisheye_uv.x,fisheye_uv.y,CHRONOGRAPH[fisheye_uv_driver]),
			vec2(0.0));
	}
	
	vec2 distort = vec2(0.0);
	if (apply_distortion == 1) {
		vec2 is = vec2(0.0);
		if (index_shift_distortion) {
			is = vec2(r3,r4);
		}
		vec2 dUV = uv + is;
		vec2 dscale = 1.0/mix(scale_distortion.xy,scale_distortion.zw,CHRONOGRAPH[distort_scale_driver]);
		if (polarize_distortion.w > 0.0) {dUV = polar_coordinates(dUV,polarize_distortion.xy,polarize_distortion.z,polarize_distortion.w);}
		dUV = scale(dUV,dscale.x,dscale.y,vec2(0.5));
		vec2 dscrl; 
		if (distort_scroll_driver == 1) {
			dscrl = scroll_distortion.xy * vec2(TIME);
		} else {
			dscrl = mix(scroll_distortion.xy,scroll_distortion.zw,CHRONOGRAPH[distort_scroll_driver]) * vec2(prg);
		}
		dscrl *= 0.5;
		distort = (vec2(texture(distort_texture,dUV+dscrl+is).r,texture(distort_texture,(1.0-dUV.yx)+dscrl-is).g) - 0.5) * 2.0;//(texture(distort_texture,dUV).r - 0.5) * 2.0;
		distort *= mix(distort_str,final_distort_str,CHRONOGRAPH[distort_str_driver]) * 0.1;
	}
	
	vec2 aUV;
	vec2 aUV2 = aUV;
	int pUV = polarize_uv;
	if (isolate_base == 2) {pUV = 0;}
	if (isolate_base != 0) {distort = vec2(0.0);}
	switch (pUV) {
		case 0: 
			aUV = uv; 
			aUV2 = projected_uv;
			break;
		case 1:
			aUV = polar_coordinates(rotate(uv,vec2(0.5),radians(polar_rot_deg)),polarize_settings.xy,polarize_settings.z,polarize_settings.w);
			aUV2 = polar_coordinates(rotate(projected_uv,vec2(0.5),radians(polar_rot_deg)),polarize_settings.xy,polarize_settings.z,polarize_settings.w);
			break;
	}
	aUV += distort;

	vec2 baseUV = aUV - mix(base_position_if.xy,base_position_if.zw,CHRONOGRAPH[base_pos_driver]);
	//vec2 base_scale = 1.0/mix(base_scale_if.xy,base_scale_if.zw,prg);

	vec4 polyBase = vec4(create_base_image(aUV,prg,base_mask_control));
	float polyShade = create_base_image(aUV,prg,2);
	if (apply_chroma != 0 && chroma_samples != 0) {
		polyBase = create_base_splits(aUV,prg,base_mask_control);
		polyShade = grayscale(create_base_splits(aUV,prg,2).rgb,1);
	}
	polyBase *= mix(base_energy.x,base_energy.y,CHRONOGRAPH[base_energy_driver]);

	/** UNCOMMENT FOR DEBUG */
	if (disable_colorize == true) {polyBase /= mix(base_energy.x,base_energy.y,CHRONOGRAPH[base_energy_driver]);}
	// DEBUG ^^^

	float shift_mod = 1.0;
	float gbs = mix(gbias_str.x,gbias_str.y,CHRONOGRAPH[gb_str_driver]);
	shift_mod *= uv2mask(rotate(baseUV,vec2(0.5),
		radians(mix(gbias_rot.x,gbias_rot.y,CHRONOGRAPH[gb_rot_driver]))
		+ radians(90.0)),gradient_bias,gbs,
	mix(gbias_edge.xy,gbias_edge.zw,CHRONOGRAPH[gb_edge_driver]));
	//switch (gradient_bias) {
		//case 1: shift_mod *= pow(baseUV.x,gbs); break;
		//case 2: shift_mod *= pow(baseUV.y,gbs); break;
		//case 3: shift_mod *= pow(1.0-baseUV.x,gbs); break;
		//case 4: shift_mod *= pow(1.0-baseUV.y,gbs); break;
		//default: break;
	//}
	shift_mod += mix(gbias_shift.x,gbias_shift.y,CHRONOGRAPH[gb_shift_driver]);
	float gm_shift = mix(shift_gradient.x,shift_gradient.y,CHRONOGRAPH[shift_gradient_driver]);
	float gm_sample = polyShade * mix(base_energy.x,base_energy.y,CHRONOGRAPH[base_energy_driver]);
	gm_sample = smoothstep(sample_edge_pow.x,sample_edge_pow.y,gm_sample);
	gm_sample = pow(gm_sample,sample_edge_pow.z);
	if (chunky_color > 0) {gm_sample = floor(gm_sample * float(chunky_color)) / float(chunky_color);}
	vec4 gm_color = texture(color_gradient,vec2(gm_sample + gm_shift,0.0) + shift_mod);

	/** UNCOMMENT FOR DEBUG */
	if (disable_colorize == true) {gm_color = vec4(1.0);}
	// DEBUG ^^^

	float alpha = 1.0;
	COLOR.rgb = polyBase.rgb * gm_color.rgb * COLOR.rgb;
	COLOR.rgb *= emission_intensity;
	switch (apply_mwm) {
		case 0:
			alpha *= texture(mesh_wide_mask,aUV2).r;
			COLOR.rgb *= texture(mesh_wide_mask,aUV2).rgb; break;
		case 1:
			alpha *= texture(mesh_wide_mask,aUV2).r;
			break;
		case 2: COLOR.rgb *= texture(mesh_wide_mask,aUV2).rgb; break;
	}
	
	alpha *= clamp(grayscale(polyBase.rgb,1),0.0,1.0) * gm_color.a * COLOR.a;
	//alpha *= fresnel(1.0,NORMAL,VIEW);
	
	alpha = smoothstep(tweak_alpha,1.0,alpha);
	/** UNCOMMENT FOR DEBUG */
	if (disable_transparency == true) {alpha = 1.0;}
	// DEBUG ^^^
	COLOR.a = alpha;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
