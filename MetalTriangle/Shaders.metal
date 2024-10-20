#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]], uint instanceID [[instance_id]]) {
    VertexOut out;

    // Modify the position based on the instanceID
    float xOffset = float(instanceID) * 0.3; // For example, offset each instance by 0.3 units on the X axis

    out.position = in.position + float4(xOffset, 0.0, 0.0, 0.0);
    out.color = in.color;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}
