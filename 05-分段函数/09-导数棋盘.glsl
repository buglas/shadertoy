// 投影坐标系
vec2 ProjectionCoord(in vec2 coord, in float scale) {
  return scale * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

// 三角形分段函数
vec2 tri(in vec2 p) {
  vec2 h = fract(p * .5) - .5;
  return 1. - 2. * abs(h);
}

// 棋盘
float checkers(in vec2 p) {
  // 模糊力度
  vec2 w = vec2(.9);
  // 求导
  vec2 i = (tri(p + 0.5 * w) - tri(p - 0.5 * w)) / w;
  return 0.5 - 0.5 * i.x * i.y;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 投影坐标
  vec2 coord = ProjectionCoord(fragCoord, 3.);
  // 棋盘
  vec3 color = vec3(checkers(coord));
  // 最终的颜色
  fragColor = vec4(color, 1);
}