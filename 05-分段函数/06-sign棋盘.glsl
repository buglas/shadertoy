// 投影坐标系
vec2 ProjectionCoord(in vec2 coord, in float scale) {
  return scale * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

// 棋盘
float checkers(in vec2 p) {
  vec2 s = sign(fract(p * .5) - .5);
  // return sign(fract(p.x* .5)- .5);
  // return fract(p.x* .5)- .5;
  // return fract(p.x* .5);
  // return fract(p.x);
  // return s.x * s.y;
  // return s.x;
  return 0.5 - 0.5 * s.x * s.y;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 投影坐标
  vec2 coord = ProjectionCoord(fragCoord, 3.);
  // 棋盘
  vec3 color = vec3(checkers(coord));

  // 最终的颜色
  fragColor = vec4(color, 1);
}