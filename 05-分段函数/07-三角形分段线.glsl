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
  // 向量AB的单位向量
  vec2 ABn = normalize(AB);
  // 向量AC
  vec2 AC = C - A;
  // 点C到直线AB的距离 = 向量AC与单位向量ABn的叉乘
  float distance = abs(AC.x * ABn.y - AC.y * ABn.x);
  // 偏移导数
  float dx = dFdx(C.x);
  // 基于偏移导数的线宽
  float width = dx * lineWidth;
  // 收缩线宽
  float shrinkWidth = max(width - dx * 2., dx);
  // 用于抗锯齿的透明度
  float a = 1. - smoothstep(shrinkWidth, width, distance);
  // 将有向距离AC和有向距离AB的比值收束在[0,1] 之间
  float ratio = clamp(dot(AC, AB) / dot(AB, AB), 0., 1.);
  // 线段
  return length(ratio * AB - AC) < width ? vec4(vec3(lineColor), a * lineColor.a) : vec4(0);
}

// 三角形
float PiecewiseFn(float x) {
  // [-0.5,0.5]
  float h = fract(x * .5) - .5;
  //[0,1,0]
  return 1. - 2. * abs(h);
}

//分段路径(当前点coord,起点star，结束点end，段数segs，线宽lineWidth，颜色sinColor)
vec4 PicewisePath(vec2 coord, float start, float end, int segs, float lineWidth, vec4 sinColor) {
  vec4 color = vec4(0);
  float step = (end - start) / float(segs);
  for(int n = 0; n < segs; n++) {
    float x = start + float(n) * step;
    float nextX = x + step;
    vec2 A = vec2(x, PiecewiseFn(x));
    vec2 B = vec2(nextX, PiecewiseFn(nextX));
    vec4 segment = Segment(coord, A, B, lineWidth, sinColor);
    if(segment.a != 0.) {
      color = segment;
    }
  }
  return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 投影坐标系缩放系数
  float scale = 3.;

  // 投影坐标
  vec2 coord = ProjectionCoord(fragCoord, scale);
  // 背景色  
  vec4 backgroundColor = vec4(0, 0, 0, 1);
  // 投影坐标系辅助对象
  vec4 projectionHelper = ProjectionHelper(coord, 2., vec4(0, .4, 0, 1), vec4(.4, 0, 0, 1), 2., vec4(vec3(.3), 1));

  /* 分段路径 */
  // 起点和终点
  float A = -2.;
  float B = 2.;
  // 分段数
  int segs = int(iResolution.x * (B - A) / (scale * 2.));
  // 路径
  vec4 path = PicewisePath(coord, A, B, segs, 2., vec4(1));
  // 最终的颜色
  fragColor = mix(backgroundColor + projectionHelper, path, path.a);
}