// original by movax20h on Shadertoy
// https://www.shadertoy.com/view/7lBfDz
// CC BY-NC-SA 3.0

shader_type canvas_item;

uniform vec2 size;
uniform vec2 moveV;
uniform float scale;

#include "common.gdshaderinc"
// #define SCALE_FACTOR 15.0
// #define SCALE_FACTOR 30.0
#define SCALE_FACTOR 2.0
// #define SCALE_FACTOR 0.1

// #define MOVE_SPEED 0.0
#define MOVE_SPEED 0.4

#define MOVE_FACTOR 0.2

// See "Common" tab for all perlin and noise helpers

float main_height(vec2 uv) {
  float h = perlin_fbm(0.1 * uv, 0.3, 19u, 1u);
  return h*h*h;
}

float continentalness(vec2 uv) {
  return perlin_fbm(0.6 * uv, 0.48, 11u, 2u);
}

float lakiness(vec2 uv) {
  return perlin_fbm(0.12 * uv, 0.45, 8u, 21u);
}

float lakes(vec2 uv) {
  //return perlin_fbm(8.7 * uv, 0.43, 4u, 22u);
  return 1.0;
}

float erossion(vec2 uv) {
  return perlin_fbm(0.1 * uv, 0.65, 6u, 3u);
}

float riverness(vec2 uv) {
  return perlin_fbm(0.13 * uv, 0.51, 10u, 4u);
}

float river(vec2 uv) {
  return perlin_fbm(1.5 * uv, 0.42, 8u, 5u);
}

// Smaller rivers going into main ones.
float river2(vec2 uv) {
  return perlin_fbm(7.5 * uv, 0.42, 10u, 51u);
}

float humidity(vec2 uv) {
  return perlin_fbm(1.1 * uv, 0.6, 7u, 6u);
}


// TODO: land_biome should also take as input values of other noises (especially
// humidity and temperature, but others too).
//
// For now, we do not use it.
vec3 land_biome(vec2 uv) {
  // Each biome is not only independent noise, but also has different persistence,
  // slightly differnt natural scale, and different number of octates.
  // These makes biomes have extra character, not just their color.
  float b1  = perlin_fbm(1.1 * uv, 0.4,  6u, 7u);
  float b2  = perlin_fbm(1.1 * uv, 0.6,  9u, 8u);
  float b2b = perlin_fbm(1.1 * uv, 0.6, 12u, 8u);  // Same noise as b2, but more octaves
  float b3  = perlin_fbm(1.1 * uv, 0.4,  5u, 9u);
  float b3b = perlin_fbm(1.1 * uv, 0.4, 10u, 9u);  // Same noise as b3, but more octaves
  float b4  = perlin_fbm(1.3 * uv, 0.7,  8u, 10u);
  float b4b = perlin_fbm(1.3 * uv, 0.7, 12u, 10u);  // Same noise as b4, but more octaves
  // TODO: Yes, it is inefficient to recalculate same octaves again.

  float b5 = perlin_fbm(2.1 * uv, 0.5, 12u, 11u);


  // Few biome base color types.
  // We avoid blue, as this is already used for ocean, deap ocean and rivers.
  //
  // Problem with using single value, is that this tends to create
  // biome X contained always inside other biome Y. While for some biomes
  // it might make sense (like dry desert inside general desert),
  // for other regions it does not make sense, and they should be more independent.
  // For this reason we only use threshold on one noise and in the inner branch,
  // we use different noise most of the time.
  // While this requires more noise evluations, it is a bit more customizable,
  // and easier to understand. I.e. each noise can have different smoothness
  // of the bounduary, as well different expected size, and numbers are more intuitive.
  if (b1 < 0.3) {
    if (b1 < 0.1) {
      return HEX(220, 20, 60);  // Crimson
    } else {
      return HEX(255, 69, 0);  // OrangeRed
    }
  } else if (b1 < 0.5) {
    if (b2 < 0.4) {  // Reuses same noise as in the final branch, so boundaries will match.
      if (b2b < 0.37) {
        return HEX(20, 238, 0);  // more green
      } else {
        return HEX(128, 128, 0);  // Olive
      }
    } else {
      if (b2 < 0.5) {
        if (0.44 < b2 && b2 < 0.46) {
          // Outer sporadic chains for trees / forests
          return HEX(0, 150, 0);  // Forest
        } else {
          return HEX(100, 100, 0);  // Brownish
        }
      } else {
        // Inner dense forests
        if (b2 < 0.6) {
          return HEX(0, 150, 0);  // Forest
        } else {
          return HEX(0, 200, 0);  // Lush forest
        }
      }
    }
  } else {
    if (b2 < 0.4) {
      return HEX(255, 215, 0);  // Gold
    } else {
      if (b3 < 0.4) {
        if (b5 < 0.5) {
          return HEX(50, 243, 77); // more green
        } else {
          return HEX(189, 183, 107); // DarkKhaki
        }
      } else {
        if (b4 < 0.5) {
          return HEX(255, 239, 213); // PapayaWhip
        } else {
          return HEX(255, 165, 0); // Orange
        }
      }
    }
  }
}

float ocean_type(vec2 uv) {
  // Very low frequency.
  return perlin_fbm(0.05 * uv, 0.5, 3u, 20u);
}


const float sea_base = 0.1;

const float sea_color = 0.3;  // shade of blue


vec3 sea_close_to_shore(vec2 uv, float below_water) {
  float ot = ocean_type(uv);
  float alpha = mapClamp(ot, 0.49, 0.51, 0.0, 1.0);
  return mix(HEX(5, 95, 75), HEX(14, 8, 99), alpha);
/*
  if (ocean_type(uv) < 0.6) {
    return HEX(5, 95, 75);  // More greenish sea
  } else {
    return HEX(14, 8, 99);  // More blue sea
  }
*/
}

vec3 deep_water(vec2 uv, float below_water) {
  // DarkBlue
  return HEX(14, 38, 129) * pow(1.0 - below_water / sea_base, 10.0);
}

vec3 sea(vec2 uv, float h) {
  float below_water = sea_base - h;  // Between 0 (surface) and sea_base (deepest)

  vec3 shallow_col = sea_close_to_shore(uv, below_water);
  vec3 deep_col = deep_water(uv, below_water);

  // return deep_col;  // Actually deep_col on its own looks good pretty good on whole sea.
  // return shallow_col;  // shallow_col on whole sea also looks good, but different, more flatish, with few deeper patches.
  // Inverting smoothstep edges (i.e. smoothstep(0.8, 0.7, ...) also has cool effect. Kind of like lagoons.
  return mix(deep_col, shallow_col, smoothstep(0.7, 1.3, vec3(map(below_water, 0.13, 0.0, 0.0, 1.0))));

/*
  if (below_water < 0.13 * sea_base) {
    return sea_close_to_shore(uv, below_water);
  } else {
    return deep_water(uv, below_water);
  }
*/
}

vec3 render(vec2 uv) {
  float h0 = main_height(uv);
  float c = continentalness(uv);
  float e = erossion(uv);
  float r = riverness(uv);
  // river (when close to middle)
  float r2 = river(uv);

  // temperature
  // humidity, verying very slowly
  float hum = humidity(uv);

  // weirdness

  float h = e * c;
  // float h = h0;


  if (h <= sea_base) {
    // Sea variations.
    return sea(uv, h);
  }

  // Otherwise land (unless river or lake).

  // Color land more green in more humid areas.
  vec3 greenFactor = vec3(1.0 - hum, hum, 1.0 - hum);

  vec3 biome_base_color = land_biome(uv);
  // biome_base_color = HEX(210, 210, 210);


  // TODO: This should only be multiplied, in some (not all) biomes.
  // Still this produces some interesting specles, more details in
  // biomes, and slow gradients here and there, which are nice.
  vec3 col = biome_base_color * greenFactor;

  // Desaturate colors a little, by reducing contrast and brightness,
  // so it is not to harsh on visualisation.
  col = ((col - 0.5) * 0.7 + 0.5) * 0.08;

  // 0 - fully connected rivers
  // 0.45 some dead ends (more open land area with no rivers)
  // 1.0 - no rivers
  float close_to_sea = (h - sea_base) / (1.0 - sea_base);  // 0 at sea, 1 at max
  float close_to_sea2 = 1.0 - pow(1.0 - close_to_sea, 14.0);

  // TODO: There is still of work here. This is a bit more complex than it started,
  // but still not great. The "spaghetti" noise for rivers tends to often
  // create loops, or rivers that connect two different oceans.
  // Would be nice to somehow break appart river so most of the time
  // it only goes to one ocean. But at the same time prevent formation
  // of "rivers" that go nowhere.
  //
  // Current structure is a bit hacky, and very sensitive to some of the constants
  // and thresholds used below. It might be possible to tweak them to make
  // any particular freeze frame look good, but hard to make it work
  // in all cases and other frames.

  // We compute some river parameters even if we do not draw river,
  // because some of these params are also used for lakes to blend with rivers.

  // Vary color of rivers a bit related to height / closness to sea
  // vec3 river_color = vec3(0.0, close_to_sea * 0.8, sea_color + (1.0 - sea_color) * close_to_sea);

  float below_water = sea_base - h;
  vec3 shallow_col = sea_close_to_shore(uv, below_water);
  vec3 sea_col = sea(uv, h);
  // vec3 river_base_color = vec3(0.0, 0.3, 0.8);
  vec3 river_base_color = vec3(0.0, close_to_sea * 0.8, sea_color + (1.0 - sea_color) * close_to_sea);
  // Actually also color of lakes.
  // vec3 river_color = mix(shallow_col, river_base_color, map(close_to_sea, 0.0, 0.1, 0.0, 1.0));
  vec3 river_color = mix(sea_col, river_base_color, mapClamp(close_to_sea, 0.0, 0.1, 0.0, 1.0));

  // Make rivers pretty thin and mostly constant width (still modulated a bit by the r2 noise),
  // but make them intrinsically widen rapidly close to the sea.
  float river_width = 0.0035 + 0.03 * pow(1.0 - close_to_sea2, 4.0);

  float distance_to_river_edge = (abs(r2 - 0.5) - river_width) / river_width;

  float l = lakiness(uv);
  if (l < 0.5) {
    float l1 = lakes(uv);
    if (l1 < 0.39) {
      // Overwrite the col, we need to do it before rivers evaluation,
      // because rivers do have smoothed edges between river and "land".
      // But should not use color of land if there is a lake.
      col = river_color;
    }
  }

  // Smooth out river edge between river and land color.
  // (If the edge is between river and lake, it will not make
  // any difference, because currently lakes have same color as river itself).
  // It would also make sense to vary tis fuzziness factory,
  // by some other low frequency noise (or maybe somehow correlate
  // with high precipitation).
  float river_edge_smoothing = 0.6;

  // When close to sea, makes river more likely, thus likely to be wider.
  // The Value is not 0.4, so there is some alluvial zone, or other transition stuff between land/river/ocean.
  if (r >= 0.444 && (close_to_sea2 < 0.71 || r < 0.58)) {  // The condition after && has tendency to break some loops, and connectivity between different oceans. Still need some tweaks.
    // close_to_sea2 can get very close to 1.0, which will make super thin rivers
    // mutliply by 0.99 to set minimum river width
    if (true) { // 0.1 * close_to_sea2 <= r2 && r2 <= 1.0 - 0.99 * close_to_sea2 * 0.1) {
      // vec3 river_color = vec3(0.0, close_to_sea * 0.8, sea_color + (1.0 - sea_color) * close_to_sea);

      // "Spaghetti" noise
      // TODO: Should also module the width of rivers on large scale, i.e. some areas with thin rivers,
      // some other continents with massive rivers, etc.
      if (abs(r2 - 0.5) < river_width) {
        return river_color;
      } else {
        // Some experiments with tributaries.
        // It works pretty nicely, but tends to creat tributaries that
        // join the main river at 90 angle. If we could vary the dinstance
        // threshold, maybe by distance to see, then we can make them join
        // at different angles too.
        if (distance_to_river_edge < 15.9 && close_to_sea2 > 0.67) {
          // Close to river, but not too close to ocean.
          // When close to the river edge, enlarge the tributary, so they merge nicely.
          // TODO: Maybe also do that when entering/exiting small lakes.
          if (abs(river2(uv) - 0.5) < 0.003 + 0.03 / pow(distance_to_river_edge, 2.0)) {
            // return HEX(0, 0, 255);
            return river_color;
          }
        }

        if (distance_to_river_edge < river_edge_smoothing) {
          return mix(river_color, col, distance_to_river_edge / river_edge_smoothing);
        } else {
          //return col;
        }
      }
    } else {
      // This usually makes some small islands or something.
      // return col;
    }
  }
  if (close_to_sea < 0.003) {
    return HEX(100, 100, 0);  // Beach sand
  }

  if (r < 0.4 && h > 0.31) {
    // Snow, a bit rare, requires low riverness, and high hight
    if (h > 0.33) {
      return HEX(200, 214, 214);  // Even higher.
    } else {
      // return HEX(160, 200, 200);  // This still does not look nice.

      // Need a bit smoother transition maybe between snow and underlying biome.

      // return smoothstep(col, HEX(160, 200, 200), vec3(map(h, 0.31, 0.33, 0.0, 1.0)));  // Wrong, but really interesting effect.
      return smoothstep(col, HEX(200, 214, 214), vec3(map(h, 0.31, 0.33, 0.0, 1.0)));  // Better.
    }
  }

  // Just land of various biomes
  return col;
}

// Transform from screen to out space
// iResolution - viewport resolution (in pixels)
vec2 transformView1(vec2 iResolution, vec4 fragCoord) {
  return (iResolution.xy - fragCoord.xy) / iResolution.y;
}

//// Scale and animate (side scroll)
vec2 transformView2(vec2 move, vec2 uv) {
  // Lets move away from negative numbers, as they are borked right now a bit,
  // and show repeting patterns, because perlin noise is broken there a bit.
  vec2 offset = vec2(100.0, 100.0) + vec2(-move.x * scale, -move.y * scale);

  return scale * uv + offset;
}

void fragment() {
	vec2 uv = transformView1(size, FRAGCOORD);
    uv = transformView2(moveV, uv);
    vec3 col = render(uv);

	vec4 res = degamma(col);

	vec3 a = pow(res.xyz, vec3(2.0));
	float gray = dot(a, vec3(0.2126, 0.7152, 0.0722));
	float gammaGray = sqrt(gray);

    COLOR = vec4(gammaGray, gammaGray, gammaGray, 1.0);
}
