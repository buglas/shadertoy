// 坐标系缩放
#define ProjectionScale 1.
// #define r .5+.5 *sin(iTime)
// 半径
#define r .7

// 投影坐标系
vec2 ProjectionCoord(in vec2 coord) {
  return ProjectionScale * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

// 圆形的sdf模型
float sdfCircle(vec2 p) {
  return length(p) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 投影坐标
  vec2 coord = ProjectionCoord(fragCoord);
  // 当前片元到圆形的有向距离
  float d = sdfCircle(coord);
  // 当有向距离小于0时，绘制白色圆形
  vec3 color = d < 0. ? vec3(1) : vec3(0);
  // 最终的颜色
  fragColor = vec4(color, 1.0);
}