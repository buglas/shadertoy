// 坐标系缩放
#define ProjectionScale 1.

// 投影坐标系
vec2 ProjectionCoord(in vec2 coord) {
  return ProjectionScale * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

// 矩形的sdf模型
float SDFRect(vec2 coord, vec2 size) {
  vec2 d = abs(coord) - size;
  return length(max(d, 0.)) + min(max(d.x, d.y), 0.);
}

// 显示距离场
vec3 SdfHelper(float cd) {
  vec3 color = 1. - sign(cd) * vec3(0, 0.5, 1);
  color *= 1. - exp(-3. * abs(cd));
  color *= .8 + .2 * sin(150. * cd);
  color = mix(color, vec3(.7, .7, 0), smoothstep(.01, 0., abs(cd)));
  return color;
}

// 鼠标选择测试
void selectTest(out vec3 color, vec2 curCoord) {
  // iMouse.z > 0.对应鼠标按下事件
  if(iMouse.z > 0.) {
    // 鼠标的投影坐标位
    vec2 mouseCoord = ProjectionCoord(iMouse.xy);
    // 鼠标到圆形的有向距离
    float md = SDFRect(mouseCoord, vec2(0.6, 0.4));
    // 当前片元到鼠标的距离
    float a = length(curCoord - mouseCoord);
    //鼠标到圆形的有向距离的绝对值
    float b = abs(md);
    // 以有向距离为半径显示一个以鼠标位中心的圆形
    color = mix(color, vec3(.7, 1, .5), smoothstep(0.007, 0., abs(a - b)));
  }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 投影坐标
  vec2 coord = ProjectionCoord(fragCoord);
  // 当前片元到矩形的有向距离
  float cd = SDFRect(coord, vec2(0.6, 0.4));
  // 当有向距离小于0时，绘制矩形
  vec3 color = SdfHelper(cd);
  // 鼠标选择测试
  selectTest(color, coord);

  // 最终的颜色
  fragColor = vec4(color, 1.0);
}