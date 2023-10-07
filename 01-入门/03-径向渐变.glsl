//裁剪坐标系
vec2 ClipCoord(in vec2 fragCoord) {
  return 2. * (fragCoord / iResolution.xy - 0.5);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 coord = ClipCoord(fragCoord);
  float coordlen = length(coord);
  fragColor = vec4(vec3(coordlen), 1);
}