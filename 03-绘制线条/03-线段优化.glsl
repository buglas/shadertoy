// 投影坐标系
vec2 ProjectionCoord(in vec2 coord, in float scale) {
  return scale * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
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
  // =投影坐标系
  return bool(axisHelper.a) ? axisHelper : gridHelper;
}

//  线段
vec4 Segment(in vec2 C, in vec2 A, in vec2 B, in float lineWidth, in vec4 lineColor) {
  // 向量AB
  vec2 AB = B - A;
  // 向量AC
  vec2 AC = C - A;
  // 基于偏移导数的线宽
  float width = dFdx(C.x) * lineWidth;
  // 将有向距离AC和有向距离AB的比值收束在[0,1] 之间
  float ratio = clamp(dot(AC, AB) / dot(AB, AB), 0., 1.);
  // 线段
  return length(ratio * AB - AC) < width ? lineColor : vec4(0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 投影坐标
  vec2 coord = ProjectionCoord(fragCoord, 3.);
  // 背景色  
  vec4 backgroundColor = vec4(0, 0, 0, 1);
  // 投影坐标系辅助对象
  vec4 projectionHelper = ProjectionHelper(coord, 2., vec4(0, .4, 0, 1), vec4(.4, 0, 0, 1), 2., vec4(vec3(.3), 1));
  // 线段
  vec4 segment = Segment(coord, vec2(-1, -1), vec2(1, 1), 1., vec4(1));
  // 最终的颜色
  fragColor = backgroundColor + projectionHelper + segment;
}