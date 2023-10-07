// 坐标系缩放
#define ProjectionScale 3.

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

// 正弦函数(自变量x，振幅a，频率omega，偏移alpha)
float SinFn(float x, float a, float omega, float alpha) {
  return a * sin(omega * x + alpha);
}

// 正弦路径(当前点coord,起点star，结束点end，段数segs，线宽lineWidth，颜色sinColor，振幅a，频率omega，偏移alpha)
vec4 SinPath(vec2 coord, float start, float end, int segs, float lineWidth, vec4 sinColor, float a, float omega, float alpha) {
  vec4 color = vec4(0);
  float step = (end - start) / float(segs);
  for(int n = 0; n < segs; n++) {
    float x = start + float(n) * step;
    float nextX = x + step;
    vec2 A = vec2(x, SinFn(x, a, omega, alpha));
    vec2 B = vec2(nextX, SinFn(nextX, a, omega, alpha));
    vec4 segment = Segment(coord, A, B, lineWidth, sinColor);
    if(segment.a != 0.) {
      color = segment;
    }
  }
  return color;
}

// 采样点
vec2[17] Samples17() {
  float d = 0.5;
  vec2 p9[9] = vec2[9](vec2(0), vec2(-d, d), vec2(0, d), vec2(d, d), vec2(d, 0), vec2(d, -d), vec2(0, -d), vec2(-d, -d), vec2(-d, 0));
  return vec2[17](p9[0], p9[1], p9[2], p9[3], p9[4], p9[5], p9[6], p9[7], p9[8], p9[1] * 2., p9[2] * 2., p9[3] * 2., p9[4] * 2., p9[5] * 2., p9[6] * 2., p9[7] * 2., p9[8] * 2.);
}

// 抗锯齿图形
vec4 SinPathAA17(vec2 coord, float start, float end, int segs, float lineWidth, vec4 sinColor, float a, float omega, float alpha) {
  vec2[17] samples = Samples17();
  vec4 sinPath = vec4(0);
  for(int i = 0; i < 17; i++) {
    vec2 pos = samples[i] * ProjectionScale / iResolution.xy;
    sinPath += SinPath(coord + pos, start, end, segs, lineWidth, sinColor, a, omega, alpha) / 17.;
  }
  return sinPath;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 投影坐标
  vec2 coord = ProjectionCoord(fragCoord);
  // 背景色  
  vec4 backgroundColor = vec4(0, 0, 0, 1);
  // 投影坐标系辅助对象
  vec4 projectionHelper = ProjectionHelper(coord, 2., vec4(0, .4, 0, 1), vec4(.4, 0, 0, 1), 2., vec4(vec3(.3), 1));
  //正弦曲线
  vec4 path = SinPathAA17(coord, -2., 2., 32, 20., vec4(1), 1., 1., iTime);
  // 最终的颜色
  fragColor = mix(backgroundColor + projectionHelper, path, path.a);
}