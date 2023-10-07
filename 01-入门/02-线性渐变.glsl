void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 coord = fragCoord / iResolution.xy;
  fragColor = vec4(coord, 1, 1);
}