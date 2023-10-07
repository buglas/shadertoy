// 坐标系缩放
#define ProjectionScale 3.
// 抗锯齿的行数和列数
#define AA 3

// 投影坐标系
vec2 ProjectionCoord(in vec2 coord) {
  return ProjectionScale * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

// 坐标轴
vec4 AxisHelper(in vec2 coord, in float axisWidth, in vec4 xAxisColor, in vec4 yAxisColor) {
  vec4 color = vec4(0, 0, 0, 0);
  float dx = dFdx(coord.x) * axisWidth;
  float dy = dFdy(coord.y) * axisWidth;
  if(abs(coord.x) < dx) {
    color = yAxisColor;
  } else if(abs(coord.y) < dy) {
    color = xAxisColor;
  }
  return color;
}

// 栅格
vec4 GridHelper(in vec2 coord, in float gridWidth, in vec4 gridColor) {
  vec4 color = vec4(0, 0, 0, 0);
  float dx = dFdx(coord.x) * gridWidth;
  float dy = dFdy(coord.y) * gridWidth;
  vec2 fraction = fract(coord);
  if(fraction.x < dx || fraction.y < dy) {
    color = gridColor;
  }
  return color;
}

// 投影坐标系辅助对象
vec4 ProjectionHelper(in vec2 coord, in float axisWidth, in vec4 xAxisColor, in vec4 yAxisColor, in float gridWidth, in vec4 gridColor) {
  // 坐标轴
  vec4 axisHelper = AxisHelper(coord, axisWidth, xAxisColor, yAxisColor);
  // 栅格
  vec4 gridHelper = GridHelper(coord, gridWidth, gridColor);
  // 投影坐标系
  return bool(axisHelper.a) ? axisHelper : gridHelper;
}

// 直线
vec4 Line(in vec2 C, in vec2 A, in vec2 B, in float lineWidth, in vec4 lineColor) {
  // 向量AB的单位向量
  vec2 ABn = normalize(B - A);
  // 向量AC
  vec2 AC = C - A;
  // 点C到直线AB的距离 = 向量AC与单位向量ABn的叉乘
  float distance = abs(AC.x * ABn.y - AC.y * ABn.x);
  // 基于偏移导数的线宽
  float width = dFdx(C.x) * lineWidth;
  // 直线
  return distance < width ? lineColor : vec4(0);
}

// 抗锯齿图形 Anti-Aliasing
vec4 LineAA(vec2 fragCoord, in vec2 A, in vec2 B, in float lineWidth, in vec4 lineColor) {
  // 初始颜色
  vec4 color = vec4(0);
  // 行列的一半
  float aa2 = float(AA / 2);
  // 逐行列遍历
  for(int y = 0; y < AA; y++) {
    for(int x = 0; x < AA; x++) {
      // 基于像素的偏移距离
      vec2 offset = vec2(float(x), float(y)) / float(AA) - aa2;
      // 投影坐标位
      vec2 coord = ProjectionCoord(fragCoord + offset);
      // 累加周围片元的颜色
      color += Line(coord, A, B, lineWidth, lineColor);
    }
  }
  // 返回周围颜色的均值
  return color / float(AA * AA);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 投影坐标
  vec2 coord = ProjectionCoord(fragCoord);
  // 背景色
  vec4 backgroundColor = vec4(0, 0, 0, 1);
  // 投影坐标系辅助对象
  vec4 projectionHelper = ProjectionHelper(coord, 2., vec4(0, .4, 0, 1), vec4(.4, 0, 0, 1), 2., vec4(vec3(.3), 1));

  // 直线
  vec4 line = LineAA(fragCoord, vec2(-1, -.1), vec2(1, .1), 3., vec4(1));
  // line = Line(coord, vec2(-1, -.1), vec2(1, .1), 3., vec4(1));

  // 最终的颜色
  fragColor = mix(backgroundColor + projectionHelper, line, line.a);
}