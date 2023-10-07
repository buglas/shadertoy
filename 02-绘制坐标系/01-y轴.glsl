// 投影坐标系
vec2 ProjectionCoord(in vec2 fragCoord) {
  return 2. * (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 coord = ProjectionCoord(fragCoord);
  vec3 rgb = vec3(0);
  if(abs(coord.x) < 0.01) {
    rgb = vec3(1);
  }
  fragColor = vec4(rgb, 1);
}