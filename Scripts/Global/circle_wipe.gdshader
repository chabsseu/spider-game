shader_type canvas_item;

uniform float radius = 2000.0;
uniform vec2 center = vec2(0.5, 0.5); // normalized (0-1) screen position
uniform vec2 screen_size = vec2(1280.0, 720.0);
uniform float edge_softness = 3.0; // pixels of anti-aliased edge

void fragment() {
	vec2 pixel_pos = UV * screen_size;
	vec2 center_pos = center * screen_size;
	float dist = distance(pixel_pos, center_pos);

	// Inside the circle = fully transparent (scene visible).
	// Outside the circle = solid black.
	float alpha = smoothstep(radius - edge_softness, radius + edge_softness, dist);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
