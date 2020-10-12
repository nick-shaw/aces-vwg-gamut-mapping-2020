uniform sampler2D frontTex, matteTex, selectiveTex;
uniform float adsk_result_w, adsk_result_h;
uniform int power_select;

// calculate compressed distance
float compress(float dist, float lim, float thr, bool invert, float power) {
  float cdist, s;
  if (dist < thr) {
    cdist = dist;
  } else {
    // power(p) compression function plot https://www.desmos.com/calculator/54aytu7hek
    if (lim < 1.0001) {
      return dist; // disable compression, avoid nan
    }
    s = (lim-thr)/pow(pow((1.0-thr)/(lim-thr),-power)-1.0,1.0/power); // calc y=1 intersect
    if (!invert) {
      cdist = thr+s*((dist-thr)/s)/(pow(1.0+pow((dist-thr)/s,power),1.0/power)); // compress
    } else {
      if (dist > (thr + s)) {
        cdist = dist; // avoid singularity
      } else {
        cdist = thr+s*pow(-(pow((dist-thr)/s,power)/(pow((dist-thr)/s,power)-1.0)),1.0/power); // uncompress
      }
    }
  }
  return cdist;
}

void main() {
  vec3 threshold;
  threshold.x = 0.815;
  threshold.y = 0.803;
  threshold.z = 0.88;
  float cyan = 0.147;
  float magenta = 0.264;
  float yellow = 0.312;
  float power_select_float = float(power_select);
  float power = 1.0 + 0.1 * power_select_float;

  // source pixels
  vec2 coords = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
  vec3 rgb = texture2D(frontTex, coords).rgb;
  float alpha = texture2D(matteTex, coords).g;
  float select = texture2D(selectiveTex, coords).g;

  // thr is the percentage of the core gamut to protect.
  vec3 thr = vec3(
    min(0.9999, threshold.x),
    min(0.9999, threshold.y),
    min(0.9999, threshold.z));

  // lim is the max distance from the gamut boundary that will be compressed
  // 0 is a no-op, 1 will compress colors from a distance of 2.0 from achromatic to the gamut boundary
  vec3 lim;
  lim = vec3(cyan+1.0, magenta+1.0, yellow+1.0);

  // achromatic axis 
  float ach = max(rgb.x, max(rgb.y, rgb.z));

  // distance from the achromatic axis for each color component aka inverse rgb ratios
  vec3 dist;
  dist.x = ach == 0.0 ? 0.0 : (ach-rgb.x)/abs(ach);
  dist.y = ach == 0.0 ? 0.0 : (ach-rgb.y)/abs(ach);
  dist.z = ach == 0.0 ? 0.0 : (ach-rgb.z)/abs(ach);

  // compress distance with user controlled parameterized shaper function
  float sat;
  vec3 csat, cdist;
  cdist = vec3(
    compress(dist.x, lim.x, thr.x, false, power),
    compress(dist.y, lim.y, thr.y, false, power),
    compress(dist.z, lim.z, thr.z, false, power));

  // recalculate rgb from compressed distance and achromatic
  // effectively this scales each color component relative to achromatic axis by the compressed distance
  vec3 crgb = vec3(
    ach-cdist.x*abs(ach),
    ach-cdist.y*abs(ach),
    ach-cdist.z*abs(ach));

  crgb = mix(rgb, crgb, select);

  gl_FragColor = vec4(crgb, alpha);
}
