// 贴图
#iChannel0 "file://images/erha.jpg"

// Wrap方式：Clamp Repeat Mirror
#iChannel0::WrapMode "Mirror"

// 采样方式：Nearest Linear NearestMipMapNearest
#iChannel0::MinFilter "NearestMipMapNearest"
#iChannel0::MagFilter "Nearest"


// 坐标系
vec2 Coord(in vec2 coord, in float scale) {
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

// 坐标系辅助对象
vec4 CoordHelper(in vec2 coord, in float axisWidth, in vec4 xAxisColor, in vec4 yAxisColor, in float gridWidth, in vec4 gridColor) {
  // 坐标轴
  vec4 axisHelper = AxisHelper(coord, axisWidth, xAxisColor, yAxisColor);
  // 栅格
  vec4 gridHelper = GridHelper(coord, gridWidth, gridColor);
  // =坐标系
  return bool(axisHelper.a) ? axisHelper : gridHelper;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 坐标
  vec2 coord = Coord(fragCoord, 2.);
  // 背景色
  vec4 backgroundColor = vec4(0, 0, 0, 1);
  // 坐标系辅助对象
  vec4 coordHelper = CoordHelper(coord, 2., vec4(0, 1, 0, 1), vec4(1, 0, 0, 1), 1., vec4(1));
  // texture(iChannel0, uv).rgb
  
  // 最终的颜色
  fragColor = backgroundColor + coordHelper+texture(iChannel0, coord).rgba;
}