#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float radius;
    float width;
    float height;
} ubuf;

// SDF Rect
float sdRoundRect(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 p = qt_TexCoord0 * vec2(ubuf.width, ubuf.height);
    vec2 center = vec2(ubuf.width * 0.5, ubuf.height * 0.5);
    vec2 size = center;
    
    // Calcula a distância usando SDF
    float d = sdRoundRect(p - center, size, ubuf.radius);
    
    // Anti-aliasing suave na borda
    float alpha = smoothstep(0.0, 1.5, -d);
    
    vec4 color = vec4(0.125, 0.133, 0.184, 1.0); // Pode ser passado como uniform depois
    fragColor = color * alpha * ubuf.qt_Opacity;
}
