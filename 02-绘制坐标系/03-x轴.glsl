// 投影坐标系
vec2 ProjectionCoord(in vec2 coord) {
  return 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
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

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 coord = ProjectionCoord(fragCoord);
  vec4 backgroundColor = vec4(0, 0, 0, 1);
  vec4 axisHelper = AxisHelper(coord, 2., vec4(0, 1, 0, 1), vec4(1, 0, 0, 1));
  fragColor = backgroundColor + axisHelper;
}