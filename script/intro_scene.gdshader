/*
	Glitch Effect Shader by Yui Kinomoto @arlez80

	MIT License
*/

shader_type canvas_item;

// 振動の強さ
uniform float shake_power = 0.03;
// 振動率
uniform float shake_rate : hint_range( 0.0, 1.0 ) = 0.2;
// 振動速度
uniform float shake_speed = 5.0;
// 振動ブロックサイズ
uniform float shake_block_size = 30.5;
// 色の分離率
uniform float shake_color_rate : hint_range( 0.0, 1.0 ) = 0.01;

// --- NUEVO: Intensidad general del efecto ---
uniform float intensity : hint_range(0.0, 1.0) = 0.5;

// スクリーン
uniform sampler2D screen_texture : hint_screen_texture;

float random( float seed )
{
	return fract( 543.2543 * sin( dot( vec2( seed, seed ), vec2( 3525.46, -54.3415 ) ) ) );
}

void fragment( )
{
	float enable_shift = float(
		random( trunc( TIME * shake_speed ) )
	<	shake_rate
	);

	vec2 fixed_uv = SCREEN_UV;
	fixed_uv.x += (
		random(
			( trunc( SCREEN_UV.y * shake_block_size ) / shake_block_size )
		+	TIME
		) - 0.5
	) * shake_power * enable_shift;

	// Color con el efecto Glitch aplicado
	vec4 pixel_color = textureLod( screen_texture, fixed_uv, 0.0 );
	pixel_color.r = mix(
		pixel_color.r
	,	textureLod( screen_texture, fixed_uv + vec2( shake_color_rate, 0.0 ), 0.0 ).r
	,	enable_shift
	);
	pixel_color.b = mix(
		pixel_color.b
	,	textureLod( screen_texture, fixed_uv + vec2( -shake_color_rate, 0.0 ), 0.0 ).b
	,	enable_shift
	);

	// --- NUEVO: Mezcla con el original ---
	// Obtenemos el color original sin modificaciones
	vec4 original_color = textureLod( screen_texture, SCREEN_UV, 0.0 );
	
	// Mezclamos según la intensidad (0.0 = original, 1.0 = full glitch)
	vec4 final_color = mix(original_color, pixel_color, intensity);
	
	COLOR = final_color;
}