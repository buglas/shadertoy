// 坐标系缩放
#define ProjectionScale 1.
// #define r .5+.4 *sin(iTime)
// 半径
#define r .3

// 投影坐标系
vec2 ProjectionCoord(in vec2 coord) {
  return ProjectionScale * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

// 圆形的sdf模型
float sdfCircle(vec2 p) {
  return length(p) - r;
}

// 显示距离场
vec3 SdfHelper(float cd) {
  vec3 color = 1. - sign(cd) * vec3(0, 0.5, 1);
  color *= 1. - exp(-3. * abs(cd));
  color *= .8 + .2 * sin(150. * cd);
  color = mix(color, vec3(.7, .7, 0), smoothstep(.01, 0., abs(cd)));
  return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 投影坐标
  vec2 coord = ProjectionCoord(fragCoord);
  // 当前片元到圆形的有向距离
  float cd = sdfCircle(coord);
  // 当有向距离小于0时，绘制白色圆形
  vec3 color = SdfHelper(cd);

  // 最终的颜色
  fragColor = vec4(color, 1.0);
}