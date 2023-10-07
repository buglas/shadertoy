// 坐标系缩放
#define PROJECTION_SCALE  1.

// 相机视点位
#define CAMERA_POS vec3(0, 2, 0)
// 视点动画
// #define CAMERA_POS mat3(cos(iTime),0,sin(iTime),0,1,0,-sin(iTime),0,cos(iTime))*(vec3(2, 4, 0)-vec3(0,0,-4))+vec3(0,0,-4)
// 相机目标点
#define CAMERA_TARGET vec3(0, 0, -4)
// 上方向
#define CAMERA_UP vec3(0, 1, 0)

// 光线推进的起始距离 
#define RAYMARCH_NEAR 0.1
// 光线推进的最远距离
#define RAYMARCH_FAR 128.
// 光线推进次数
#define RAYMARCH_TIME 512
// 当推进后的点位距离物体表面小于RAYMARCH_PRECISION时，默认此点为物体表面的点
#define RAYMARCH_PRECISION 0.001 

// 点光源位置
#define LIGHT_POS vec3(3,4, -1)

// 相邻点的抗锯齿的行列数
#define AA 3

// 栅格图像的z位置
#define SCREEN_Z -1.

// 投影坐标系
vec2 ProjectionCoord(in vec2 coord) {
  return PROJECTION_SCALE * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

// 水平面的SDF模型
float SDFPlane(vec3 coord) {
  return coord.y;
}

// 计算球体的法线
vec3 SDFNormal(in vec3 p) {
  const float h = 0.0001;
  const vec2 k = vec2(1, -1);
  return normalize(k.xyy * SDFPlane(p + k.xyy * h) +
    k.yyx * SDFPlane(p + k.yyx * h) +
    k.yxy * SDFPlane(p + k.yxy * h) +
    k.xxx * SDFPlane(p + k.xxx * h));
}

// 视图旋转矩阵
mat3 RotateMatrix() {
  //基向量c，视线
  vec3 c = normalize(CAMERA_POS - CAMERA_TARGET);
  //基向量a，视线和上方向的垂线
  vec3 a = cross(CAMERA_UP, c);
  //基向量b，修正上方向
  vec3 b = cross(c, a);
  //正交旋转矩阵
  return mat3(a, b, c);
}

// 光线推进数据的结构体
struct RayMarchData {
  vec3 pos;
  bool crash;
};

// 将RayMarch与渲染分离
RayMarchData RayMarch(vec3 ro, vec3 rd) {
  float d = RAYMARCH_NEAR;
  // 光线推进次数
  RayMarchData rm;
  rm = RayMarchData(ro, false);
  for(int i = 0; i < RAYMARCH_TIME && d < RAYMARCH_FAR; i++) {
    // 光线推进后的点位
    vec3 p = ro + d * rd;
    // 光线推进后的点位到模型的有向距离
    float curD = SDFPlane(p);
    // 若有向距离小于一定的精度，默认此点在模型表面
    if(curD < RAYMARCH_PRECISION) {
      rm = RayMarchData(p, true);
      break;
    }
    // 距离累加
    d += curD;
  }
  return rm;
}

// 棋盘格
float checkers(in vec2 uv) {
  vec2 grid = floor(uv);
  return mod(grid.x + grid.y, 2.);
}

// 渲染
vec3 Render(vec2 coord) {
  // 从相机视点到当前片元的射线
  RayMarchData rm = RayMarch(CAMERA_POS, normalize(RotateMatrix() * vec3(coord, SCREEN_Z)));
  // 片元颜色
  vec3 color = vec3(0);
  // 如果光线推进到SDF模型上
  if(rm.crash) {
    color = vec3(checkers(rm.pos.xz));
  }
  return color;
}

// 抗锯齿 Anti-Aliasing
vec3 Render_anti(vec2 fragCoord) {
  // 初始颜色
  vec3 color = vec3(0);
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
      color += Render(coord);
    }
  }
  // 返回周围颜色的均值
  return color / float(AA * AA);
}

/* 绘图函数，画布中的每个片元都会执行一次，执行方式是并行的。
fragColor 输出参数，用于定义当前片元的颜色。
fragCoord 输入参数，当前片元的位置，原点在画布左下角，右侧边界为画布的像素宽，顶部边界为画布的像素高
*/
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // 光线推进
  vec3 color = Render_anti(fragCoord);
  // vec3 color = Render(ProjectionCoord(fragCoord));
  // 最终颜色
  fragColor = vec4(color, 1);
}
