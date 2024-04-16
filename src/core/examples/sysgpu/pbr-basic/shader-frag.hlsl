static float4 _3474;
static float3 _3547;
static float4 _3621[4];
static uint _4116;

cbuffer t_UBO : register(b0, space0)
{
    row_major float4 t_ubo_projection[4] : packoffset(c0);
    row_major float4 t_ubo_model[4] : packoffset(c4);
    row_major float4 t_ubo_view[4] : packoffset(c8);
    row_major float3 t_ubo_cam_pos : packoffset(c12);
};

cbuffer t_UBOShared : register(b1, space0)
{
    row_major float4 t_ubo_params_lights[4] : packoffset(c0);
};

cbuffer t_MaterialParams : register(b2, space0)
{
    row_major float t_material_roughness : packoffset(c0);
    row_major float t_material_metallic : packoffset(c0.y);
    row_major float t_material_r : packoffset(c0.z);
    row_major float t_material_g : packoffset(c0.w);
    row_major float t_material_b : packoffset(c1);
};

cbuffer t_ObjectParams : register(b3, space0)
{
    row_major float3 t_object_position : packoffset(c0);
};


static float3 t_position;
static float3 t_normal;
static float4 t_frag_out;

struct SPIRV_Cross_Input
{
    float3 t_position : TEXCOORD0;
    float3 t_normal : TEXCOORD1;
};

struct SPIRV_Cross_Output
{
    float4 t_frag_out : SV_Target0;
};

void initializer_of_anon_2314(out ??? _4467[27])
{
    ??? _671[27];
    _671[0u] = ???(79);
    _671[1u] = ???(112);
    _671[2u] = ???(68);
    _671[3u] = ???(101);
    _671[4u] = ???(99);
    _671[5u] = ???(111);
    _671[6u] = ???(114);
    _671[7u] = ???(97);
    _671[8u] = ???(116);
    _671[9u] = ???(101);
    _671[10u] = ???(32);
    _671[11u] = ???(37);
    _671[12u] = ???(112);
    _671[13u] = ???(116);
    _671[14u] = ???(114);
    _671[15u] = ???(32);
    _671[16u] = ???(76);
    _671[17u] = ???(111);
    _671[18u] = ???(99);
    _671[19u] = ???(97);
    _671[20u] = ???(116);
    _671[21u] = ???(105);
    _671[22u] = ???(111);
    _671[23u] = ???(110);
    _671[24u] = ???(32);
    _671[25u] = ???(48);
    _671[26u] = ???(0);
    _4467 = _671;
}

void gpu_fragmentOrigin_anon_963()
{
}

void gpu_location_anon_964(??? _4534[27])
{
}

void debug_assert(bool _4108)
{
    uint _4119;
    if (!_4108)
    {
    }
    else
    {
        _4119 = 2u;
    }
    if (_4119 == 2u)
    {
        return;
    }
}

float3 gpu_normalize_anon_965(float3 _3730)
{
    debug_assert(true);
    return normalize(_3730);
}

float gpu_dot_anon_2115(float3 _4126, float3 _4127)
{
    debug_assert(true);
    return dot(_4126, _4127);
}

float math_clamp_anon_2116(float _4134)
{
    debug_assert(true);
    return max(0.0f, min(1.0f, _4134));
}

float t_D_GGX(float _4143, float _4144)
{
    float alpha = _4144 * _4144;
    float alpha2 = alpha * alpha;
    float denom = ((_4143 * _4143) * (alpha2 - 1.0f)) + 1.0f;
    return alpha2 / ((3.1415927410125732421875f * denom) * denom);
}

float t_G_SchlicksmithGGX(float _4159, float _4160, float _4161)
{
    float r = _4161 + 1.0f;
    float k = (r * r) / 8.0f;
    return (_4159 / ((_4159 * (1.0f - k)) + k)) * (_4160 / ((_4160 * (1.0f - k)) + k));
}

float3 t_material_color()
{
    float3 _3838;
    _3838.x = t_MaterialParams(t_material_roughness, t_material_metallic, t_material_r, t_material_g, t_material_b).r;
    _3838.y = t_MaterialParams(t_material_roughness, t_material_metallic, t_material_r, t_material_g, t_material_b).g;
    _3838.z = t_MaterialParams(t_material_roughness, t_material_metallic, t_material_r, t_material_g, t_material_b).b;
    return _3838;
}

float3 gpu_mix_anon_2117(float3 _4395, float3 _4396, float3 _4397)
{
    debug_assert(true);
    return lerp(_4395, _4396, _4397);
}

float gpu_pow_anon_2118(float _4403, float _4404)
{
    debug_assert(true);
    return pow(_4403, _4404);
}

float3 t_F_Schlick(float _4179, float _4180)
{
    float3 _4183;
    _4183.x = _4180;
    _4183.y = _4180;
    _4183.z = _4180;
    float3 _4194;
    _4194.x = 0.039999999105930328369140625f;
    _4194.y = 0.039999999105930328369140625f;
    _4194.z = 0.039999999105930328369140625f;
    float3 F0 = gpu_mix_anon_2117(_4194, t_material_color(), _4183);
    float3 _4202;
    _4202.x = 1.0f;
    _4202.y = 1.0f;
    _4202.z = 1.0f;
    float _4212 = gpu_pow_anon_2118(1.0f - _4179, 5.0f);
    float3 _4215;
    _4215.x = _4212;
    _4215.y = _4212;
    _4215.z = _4212;
    return F0 + ((_4202 - F0) * _4215);
}

float3 t_BRDF(float3 _3740, float3 _3741, float3 _3742, float _3743, float _3744)
{
    float dotNV = math_clamp_anon_2116(gpu_dot_anon_2115(_3742, _3741));
    float dotNL = math_clamp_anon_2116(gpu_dot_anon_2115(_3742, _3740));
    float3 _3757;
    _3757.x = 1.0f;
    _3757.y = 1.0f;
    _3757.z = 1.0f;
    float3 _3766;
    _3766.x = 0.0f;
    _3766.y = 0.0f;
    _3766.z = 0.0f;
    float3 color = _3766;
    uint _3829;
    if (dotNL > 0.0f)
    {
        float _3778 = t_D_GGX(math_clamp_anon_2116(gpu_dot_anon_2115(_3742, gpu_normalize_anon_965(_3741 + _3740))), _3744);
        float3 _3780;
        _3780.x = _3778;
        _3780.y = _3778;
        _3780.z = _3778;
        float _3788 = t_G_SchlicksmithGGX(dotNL, dotNV, _3744);
        float3 _3790;
        _3790.x = _3788;
        _3790.y = _3788;
        _3790.z = _3788;
        float _3804 = (4.0f * dotNL) * dotNV;
        float3 _3805;
        _3805.x = _3804;
        _3805.y = _3804;
        _3805.z = _3804;
        float3 _3815;
        _3815.x = dotNL;
        _3815.y = dotNL;
        _3815.z = dotNL;
        color += ((((_3780 * t_F_Schlick(dotNV, _3743)) * _3790) / _3805) * _3815);
        _3829 = 36u;
    }
    else
    {
        _3829 = 36u;
    }
    if (_3829 == 36u)
    {
        return color;
    }
}

float3 gpu_pow_anon_966(float3 _3852, float3 _3853)
{
    debug_assert(true);
    return pow(_3852, _3853);
}

void t_frag(??? _4466[27])
{
    gpu_fragmentOrigin_anon_963();
    gpu_location_anon_964(_4466);
    float3 N = gpu_normalize_anon_965(t_normal);
    float3 V = gpu_normalize_anon_965(t_UBO(t_ubo_projection, t_ubo_model, t_ubo_view, t_ubo_cam_pos).cam_pos - t_position);
    float3 _495;
    _495.x = 0.0f;
    _495.y = 0.0f;
    _495.z = 0.0f;
    float3 Lo = _495;
    uint64_t _503 = 0ull;
    float3 _542;
    uint _576;
    for (;;)
    {
        uint _570;
        if (_503 < 4ull)
        {
            float4 _520[4] = t_UBOShared(t_ubo_params_lights).lights;
            float4 _523 = _520[_503];
            float4 _528[4] = t_UBOShared(t_ubo_params_lights).lights;
            float4 _531 = _528[_503];
            float4 _536[4] = t_UBOShared(t_ubo_params_lights).lights;
            float4 _539 = _536[_503];
            _542.x = _523.x;
            _542.y = _531.y;
            _542.z = _539.z;
            Lo += t_BRDF(gpu_normalize_anon_965(_542 - t_position), V, N, t_MaterialParams(t_material_roughness, t_material_metallic, t_material_r, t_material_g, t_material_b).metallic, t_MaterialParams(t_material_roughness, t_material_metallic, t_material_r, t_material_g, t_material_b).roughness);
            _570 = 40u;
        }
        else
        {
            _570 = 37u;
        }
        if (_570 == 40u)
        {
            _503 += 1ull;
            continue;
        }
        else
        {
            _576 = _570;
            break;
        }
    }
    if (_576 == 37u)
    {
        float3 _586;
        _586.x = 0.0199999995529651641845703125f;
        _586.y = 0.0199999995529651641845703125f;
        _586.z = 0.0199999995529651641845703125f;
        float3 color = t_material_color() * _586;
        color += Lo;
        float3 _602;
        _602.x = 0.4544999897480010986328125f;
        _602.y = 0.4544999897480010986328125f;
        _602.z = 0.4544999897480010986328125f;
        color = gpu_pow_anon_966(color, _602);
        float3 _611 = color;
        float3 _615 = color;
        float3 _619 = color;
        float4 _622;
        _622.x = _611.x;
        _622.y = _615.y;
        _622.z = _619.z;
        _622.w = 1.0f;
        t_frag_out = _622;
        return;
    }
}

void frag_main()
{
    ??? _4625[27];
    initializer_of_anon_2314(_4625);
    t_frag(_4625);
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    t_position = stage_input.t_position;
    t_normal = stage_input.t_normal;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.t_frag_out = t_frag_out;
    return stage_output;
}
