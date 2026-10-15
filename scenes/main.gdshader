shader_type canvas_item;

// --- Background Settings ---
uniform vec4 space_color : source_color = vec4(0.02, 0.01, 0.04, 1.0); // Deep cosmic dark purple
uniform float star_density : hint_range(1.0, 20.0) = 8.0;
uniform float base_star_size : hint_range(0.01, 0.2) = 0.06;
uniform vec2 camera_offset = vec2(0.0, 0.0);

// --- Nebula Customization ---
uniform vec4 nebula_color_1 : source_color = vec4(0.0, 0.4, 0.8, 0.3); // Neon Cyan/Blue cloud tint
uniform vec4 nebula_color_2 : source_color = vec4(0.6, 0.0, 0.6, 0.2); // Synthwave Violet/Pink tint
uniform float nebula_scale : hint_range(0.1, 5.0) = 1.2;             // Size/density of the dust patches
uniform float nebula_speed : hint_range(0.01, 0.5) = 0.05;            // Very subtle auto-drift speed

// Deterministic noise for generating random star fields
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 2D Value Noise function used to generate smooth organic cloud shapes
// Upgraded high-precision noise function to eliminate triangle artifacts
float noise(vec2 p) {
    // Keep positions wrapped inside a localized cell boundary
    p = mod(p, 256.0); 
    
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Smooth Cubic Hermite interpolation (eliminates harsh angular lines)
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(mix(hash(i + vec2(0.0,0.0)), hash(i + vec2(1.0,0.0)), u.x),
               mix(hash(i + vec2(0.0,1.0)), hash(i + vec2(1.0,1.0)), u.x), u.y);
}


// Layered noise (FBM) for complex, realistic smoke and plasma patterns
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial artifacts
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.5)));
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = rot * p * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    // 1. NEBULA DUST GENERATION
    // Nebulas are far away, so they use a very slow camera parallax multiplier (0.05)
    vec2 nebula_uv = (FRAGCOORD.xy + (camera_offset * 0.05)) * 0.002 * nebula_scale;
    
    // Add subtle automated morphing to the gas clouds over time
    float time_drift = TIME * nebula_speed;
    float n1 = fbm(nebula_uv + time_drift);
    float n2 = fbm(nebula_uv - time_drift + vec2(1.5, 2.3));
    
    // Create rich cloud depth by blending two different noise shapes together
    float cloud_mask_1 = smoothstep(0.3, 0.7, n1);
    float cloud_mask_2 = smoothstep(0.2, 0.8, n2);
    
    // Construct the baseline dark sky environment with the mixed nebula tints
    vec3 mixed_nebula = mix(space_color.rgb, nebula_color_1.rgb, cloud_mask_1 * nebula_color_1.a);
    mixed_nebula = mix(mixed_nebula, nebula_color_2.rgb, cloud_mask_2 * nebula_color_2.a);
    
    vec3 final_color = mixed_nebula;
    
    // 2. PARALLAX STARFIELD GENERATION
    for (float i = 1.0; i <= 3.0; i++) {
        float parallax_speed = i * 0.2;
        vec2 world_pos = FRAGCOORD.xy + (camera_offset * parallax_speed);
        
        vec2 grid_uv = world_pos * (star_density / (i * 100.0));
        vec2 id = floor(grid_uv);
        vec2 local_uv = fract(grid_uv) - 0.5;
        
        vec2 rand_offset = vec2(hash(id), hash(id + 1.23)) - 0.5;
        float dist = length(local_uv - rand_offset * 0.7);
        
        float star_rand = hash(id + 4.56);
        float star_size = base_star_size * star_rand;
        
        float star = smoothstep(star_size, star_size - 0.02, dist);
        float twinkle = (sin(TIME * (star_rand * 4.0) + star_rand * 10.0) + 1.0) * 0.5;
        float brightness = mix(0.4, 1.5, twinkle);
        
        // Render stars directly on top of the colorful clouds
        final_color += vec3(star) * (i / 3.0) * brightness;
    }
    
    COLOR = vec4(final_color, space_color.a);
}
