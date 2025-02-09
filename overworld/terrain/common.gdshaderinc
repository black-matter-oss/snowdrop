// original by movax20h on Shadertoy
// https://www.shadertoy.com/view/7lBfDz
// CC BY-NC-SA 3.0

// Helper Functions
uint rotl(uint x, uint r) {
  return (x << r) | (x >> (32u - r));
}

uint rotr(uint x, uint r) {
  return (x >> r) | (x << (32u - r));
}

uint fmix(uint h) {
  h ^= h >> 16u;
  h *= 0x85ebca6bu;
  h ^= h >> 13u;
  h *= 0xc2b2ae35u;
  h ^= h >> 16u;
  return h;
}


// commonly used constants
#define c1 0xcc9e2d51u
#define c2 0x1b873593u

uint mur(uint a, uint h) {
  // Helper from Murmur3 for combining two 32-bit values.
  a *= c1;
  a = rotr(a, 17u);
  a *= c2;
  h ^= a;
  h = rotr(h, 19u);
  return h * 5u + 0xe6546b64u;
}

// Adapted from MurmurHash3_x86_32 from https://github.com/aappleby/smhasher
uint murmur3(uvec4 seed) {
  uint h = 0u;
  uint k = seed.x;

  k *= c1;
  k = rotl(k,15u);
  k *= c2;

  h ^= k;
  h = rotl(h,13u);
  h = h*5u+0xe6546b64u;

  k = seed.y;

  k *= c1;
  k = rotl(k,15u);
  k *= c2;

  h ^= k;
  h = rotl(h,13u);
  h = h*5u+0xe6546b64u;

  k = seed.z;

  k *= c1;
  k = rotl(k,15u);
  k *= c2;

  h ^= k;
  h = rotl(h,13u);
  h = h*5u+0xe6546b64u;

  k = seed.w;

  k *= c1;
  k = rotl(k,15u);
  k *= c2;

  h ^= k;
  h = rotl(h,13u);
  h = h*5u+0xe6546b64u;

  h ^= 16u;

  return fmix(h);
}

#undef c1
#undef c2


// http://www.jcgt.org/published/0009/03/02/
uvec3 pcg3d(uvec3 v) {
  v = v * 1664525u + 1013904223u;

  v.x += v.y*v.z;
  v.y += v.z*v.x;
  v.z += v.x*v.y;

  v ^= v >> 16u;

  v.x += v.y*v.z;
  v.y += v.z*v.x;
  v.z += v.x*v.y;

  return v;
}

uint xorshift128(uvec4 v) {
  v.w ^= v.w << 11u;
  v.w ^= v.w >> 8u;
  v = v.wxyz;
  v.x ^= v.y;
  v.x ^= v.y >> 19u;
  return v.x;
}

vec2 hash(vec2 p, uint seed, uint subseed) {
  //uint v = xorshift128(uvec4(p.xy, seed, subseed));
  uint v = murmur3(uvec4(uvec2(p.xy), seed, subseed));
  uvec3 res = pcg3d(uvec3(uvec2(p), v));
  return vec2(res.xy) * (1.0 / float(0xffffffffu));
}

vec2 randomGradient(vec2 p, uint seed, uint subseed) {
  vec2 r = hash(p, seed, subseed);
  // r.xy are in -1.0 to 1.0 range. Extend range to bigger domain.
  float n = 1000001.0 * r.x + r.y;
#if 1
  // Simple random vectors
  return vec2(cos(float(n)), sin(float(n)));
#else
  // This requires n to be int.
  // Perlin style vectors
  n &= 7;
  vec2 gr = vec2(n&1,n>>1)*2.0-1.0;
  return ( n>=6 ) ? vec2(0.0,gr.x) :
         ( n>=4 ) ? vec2(gr.x,0.0) :
                            gr;
#endif
}

float lerp(float a, float b, float t) {
  return a + t * (b - a);
}

// Output is in range [-1, 1]
float perlin_noise_2(vec2 p, uint seed, uint subseed) {
  vec2 i = floor(p);
  vec2 f = fract(p);

  // Grid points
  // p2 p3
  // p0 p1
  vec2 p0 = vec2(0.0, 0.0);
  vec2 p1 = vec2(1.0, 0.0);
  vec2 p2 = vec2(0.0, 1.0);
  vec2 p3 = vec2(1.0, 1.0);

  // Distance vectors to each grid point
  vec2 s0 = f - p0;
  vec2 s1 = f - p1;
  vec2 s2 = f - p2;
  vec2 s3 = f - p3;

  // Random gradient vectors on each grid point
  vec2 g0 = randomGradient(i + p0, seed, subseed);
  vec2 g1 = randomGradient(i + p1, seed, subseed);
  vec2 g2 = randomGradient(i + p2, seed, subseed);
  vec2 g3 = randomGradient(i + p3, seed, subseed);

  // Gradient values
  float q0 = dot(s0, g0);
  float q1 = dot(s1, g1);
  float q2 = dot(s2, g2);
  float q3 = dot(s3, g3);

  // Interpolant weights
  vec2 u = f * f * (3.0 - 2.0 * f);

  // Bilinear interpolation
  float l0 = lerp(q0, q1, u.x);
  float l1 = lerp(q2, q3, u.x);
  float l2 = lerp(l0, l1, u.y);

  return l2;
}

// Output is in range [0, 1].
float perlin_fbm(vec2 uv, float persistence, uint octaves, uint seed)  {
  float total = 0.0;
  float maxValue = 0.0;
  float amplitude = 1.0;
  float frequency = 1.0;

  for (uint i = 0u; i < octaves; i++) {
    total += perlin_noise_2(uv * frequency, seed, i) * amplitude;
    maxValue += amplitude;
    amplitude *= persistence;
    frequency *= 2.0;
  }
  return (total / maxValue + 1.0) * 0.5;
}




// Color related functions


// Converts a color (0-255 range) from sRGB to linear space
// This is useful as most software and color palets online,
// will only show values in sRGB values / hex.
//
// Adapted from https://gamedev.stackexchange.com/questions/92015/optimized-linear-to-srgb-glsl
// by Tynach and Pieter-Jan Briers
//
// Performance should not matter much, as we pass constants to this function,
// so shader compiler should constant fold entire function.
vec3 HEX(int r, int g, int b) {
    vec3 sRGB = vec3(float(r) / 255.0, float(g) / 255.0, float(b) / 255.0);
    bvec3 cutoff = lessThan(sRGB, vec3(0.04045));
    vec3 higher = pow((sRGB + vec3(0.055)) / vec3(1.055), vec3(2.4));
    vec3 lower = sRGB / vec3(12.92);

    return mix(higher, lower, cutoff);
}

#define PINK vec3(255.0 / 255.0, 19.0 / 255.0, 203.0 / 255.0)
#define PINK_LINEAR vec3(255.0 / 255.0, 0.0 / 255.0, 203.0 / 255.0)

// From linear [0, 1] to sRGB [0, 255].
// Alpha channel is untouched.
vec4 toSRGB(vec4 linearRGB) {
  bvec3 cutoff = lessThan(linearRGB.rgb, vec3(0.0031308));
  vec3 higher = vec3(1.055) *pow(linearRGB.rgb, vec3(1.0 / 2.4)) - vec3(0.055);
  vec3 lower = linearRGB.rgb * 12.92;

  return vec4(mix(higher, lower, cutoff), linearRGB.a);
}

// From linear to sRGB
vec4 degamma(vec3 col) {
  if (col.x < 0.0 || col.y < 0.0 || col.z < 0.0) {
    col = PINK_LINEAR;
  }
  return toSRGB(vec4(col.xyz, 255.0));
}

// Without gamma correction
vec4 degamma0(vec3 col) {
  if (col.x < 0.0 || col.y < 0.0 || col.z < 0.0) {
    col = PINK_LINEAR;
  }
  return vec4(col.xyz, 1.0);
}


float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

float mapClamp(float value, float min1, float max1, float min2, float max2) {
  return clamp(map(value, min1, max1, min2, max2), 0.0, 1.0);
}
