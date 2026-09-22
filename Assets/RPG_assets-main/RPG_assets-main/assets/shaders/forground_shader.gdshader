shader_type canvas_item;

uniform float MULTIPLIER = 0.56;
uniform float SCALE = 0.5;
uniform float SOFTNESS = 0.45;

// Opacity with no foreground occluder.
uniform float BASE_OPACITY : hint_range(0.0, 1.0) = 0.0;

// Opacity with foreground occluders.
uniform float TARGET_OPACITY : hint_range(0.0, 1.0) = 0.6;

// 0 = BASE_OPACITY
// 1 = TARGET_OPACITY
uniform float BLEND : hint_range(0.0, 1.0) = 0.0;


void fragment() {

	float val = distance(
		vec2(
			UV.x,
			UV.y * MULTIPLIER
		),
		vec2(
			0.5,
			0.5 * MULTIPLIER
		)
	);

	val /= SCALE;

	float vignette = smoothstep(
		0.0,
		SOFTNESS,
		val
	);

	// Smoothly interpolate opacity in both directions:
	//
	// BLEND = 0 → BASE_OPACITY
	// BLEND = 1 → TARGET_OPACITY
	float opacity = mix(
		BASE_OPACITY,
		TARGET_OPACITY,
		BLEND
	);

	vignette *= opacity;

	if (COLOR.a > 0.99) {

		COLOR = vec4(
			COLOR.rgb,
			vignette
		);
	}
}