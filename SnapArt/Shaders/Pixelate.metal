#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 pixelate(float2 position, half4 color, float progress) {
    float pixelSize = mix(1.0, 30.0, progress);
    float2 pixelatedPosition = floor(position / pixelSize) * pixelSize;
    
    // Transition to black based on progress
    half4 finalColor = mix(color, half4(0.0, 0.0, 0.0, 1.0), half(progress));
    
    return finalColor;
} 