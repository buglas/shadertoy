// 投影坐标系
vec2 ProjectionCoord(in vec2 coord, in float scale) {
  return scale * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

// 棋盘
float checkers(in vec2 p) {
  // [1,2,3,……]
  ivec2 ip = ivec2(round(p + .5));
  //^按位异或、&按位与
  return float((ip.x ^ ip.y) & 1);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 投影坐标
  vec2 coord = ProjectionCoord(fragCoord, 3.);
  // 棋盘
  vec3 color = vec3(checkers(coord));

  // 最终的颜色
  fragColor = vec4(color, 1);
}