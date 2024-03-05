@group(0) @binding(0) var<uniform> ubo : UBO;
@group(0) @binding(1) var<uniform> uboParams : UBOShared;
@group(0) @binding(2) var<uniform> material : MaterialParams;
@group(0) @binding(3) var<uniform> object : ObjectParams;

struct VertexOut {
    @builtin(position) position_clip : vec4<f32>,
    @location(0) fragPosition : vec3<f32>,
    @location(1) fragNormal : vec3<f32>,
}

struct MaterialParams {
    roughness : f32,
    metallic : f32,
    r : f32,
    g : f32,
    b : f32
}

struct UBOShared {
    lights : array<vec4<f32>, 4>,
}

struct UBO {
    projection : mat4x4<f32>,
    model : mat4x4<f32>,
    view : mat4x4<f32>,
    camPos : vec3<f32>,
}

struct ObjectParams {
    position : vec3<f32>
}

@vertex fn vertex_main(
     @location(0) position : vec3<f32>,
     @location(1) normal : vec3<f32> 
) -> VertexOut {
    var output : VertexOut;
    var locPos = vec4<f32>(ubo.model * vec4<f32>(position, 1.0));
    output.fragPosition = locPos.xyz + object.position;
    output.fragNormal = mat3x3<f32>(ubo.model[0].xyz, ubo.model[1].xyz, ubo.model[2].xyz) * normal;
    output.position_clip = ubo.projection * ubo.view * vec4<f32>(output.fragPosition, 1.0);
    return output;
}

@fragment fn frag_main(
     @location(0) position : vec3<f32>,
     @location(1) normal: vec3<f32> 
) -> @location(0) vec4<f32> {
    var N : vec3<f32> = normalize(normal);
    var V : vec3<f32> = normalize(ubo.camPos - position);
    var Lo = vec3<f32>(0.0);
    // Specular contribution
    for(var i: i32 = 0; i < 4; i++) {
        var L : vec3<f32> = normalize(uboParams.lights[i].xyz - position);
        Lo += BRDF(L, V, N, material.metallic, material.roughness);
    }
    // Combine with ambient
    var color : vec3<f32> = material_color() * 0.02;
    color += Lo;
    // Gamma correct
    color = pow(color, vec3<f32>(0.4545));
    return vec4<f32>(color, 1.0);
}

const PI : f32 = 3.14159265359;

fn material_color() -> vec3<f32> {
    return vec3<f32>(material.r, material.g, material.b);
}

// Normal Distribution function --------------------------------------
fn D_GGX(dotNH : f32, roughness : f32) -> f32 {
    var alpha : f32 = roughness * roughness;
    var alpha2 : f32 = alpha * alpha;
    var denom : f32 = dotNH * dotNH * (alpha2 - 1.0) + 1.0;
    return alpha2 / (PI * denom * denom);
}

// Geometric Shadowing function --------------------------------------
fn G_SchlicksmithGGX(dotNL : f32, dotNV : f32, roughness : f32) -> f32 {
    var r : f32 = roughness + 1.0;
    var k : f32 = (r * r) / 8.0;
    var GL : f32 = dotNL / (dotNL * (1.0 - k) + k);
    var GV : f32 = dotNV / (dotNV * (1.0 - k) + k);
    return GL * GV;
}

// Fresnel function ----------------------------------------------------
fn F_Schlick(cosTheta : f32, metallic : f32) -> vec3<f32> {
    var F0 : vec3<f32> = mix(vec3<f32>(0.04), material_color(), metallic);
    var F : vec3<f32> = F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
    return F;
}

// Specular BRDF composition --------------------------------------------
fn BRDF(L : vec3<f32>, V : vec3<f32>, N : vec3<f32>, metallic : f32, roughness : f32) -> vec3<f32> {
    var H : vec3<f32> = normalize(V + L);
    var dotNV : f32 = clamp(dot(N, V), 0.0, 1.0);
    var dotNL : f32 = clamp(dot(N, L), 0.0, 1.0);
    var dotLH : f32 = clamp(dot(L, H), 0.0, 1.0);
    var dotNH : f32 = clamp(dot(N, H), 0.0, 1.0);
    var lightColor = vec3<f32>(1.0);
    var color = vec3<f32>(0.0);
    if(dotNL > 0.0) {
        var rroughness : f32 = max(0.05, roughness);
        // D = Normal distribution (Distribution of the microfacets)
        var D : f32 = D_GGX(dotNH, roughness);
        // G = Geometric shadowing term (Microfacets shadowing)
        var G : f32 = G_SchlicksmithGGX(dotNL, dotNV, roughness);
        // F = Fresnel factor (Reflectance depending on angle of incidence)
        var F : vec3<f32> = F_Schlick(dotNV, metallic);
        var spec : vec3<f32> = (D * F * G) / (4.0 * dotNL * dotNV);
        color += spec * dotNL * lightColor;
    }
    return color;
}