// 坐标系缩放
#define PROJECTION_SCALE  1.

// 球体的球心位置
#define SPHERE_POS vec3(0, 1, -4)
// 球体的半径
#define SPHERE_R 1.0
// 球体的漫反射系数
#define SPHERE_KD vec3(1)

// 相机视点位
#define CAMERA_POS vec3(0, 1.5, 0)
// 相机目标点
#define CAMERA_TARGET vec3(0, 1, -4)
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

// 投影坐标系
vec2 ProjectionCoord(in vec2 coord) {
  return PROJECTION_SCALE * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

//球体的SDF模型
float SDFSphere(vec3 coord) {
  return length(coord - SPHERE_POS) - SPHERE_R;
}

// 水平面的SDF模型
float SDFPlane(vec3 coord) {
  return coord.y;
}

// 所有的SDF模型
float SDFAll(vec3 coord) {
  return min(SDFSphere(coord), SDFPlane(coord));
}

// 计算球体的法线
vec3 SDFNormal(in vec3 p) {
  const float h = 0.0001;
  const vec2 k = vec2(1, -1);
  return normalize(k.xyy * SDFAll(p + k.xyy * h) +
    k.yyx * SDFAll(p + k.yyx * h) +
    k.yxy * SDFAll(p + k.yxy * h) +
    k.xxx * SDFAll(p + k.xxx * h));
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
  // 光线推进位置
  vec3 pos;
  // 是否碰到sdf模型
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
    float curD = SDFAll(p);
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

// 精准投影
float Shadow(in vec3 ro, in vec3 rd) {
  for(float t = RAYMARCH_NEAR; t < RAYMARCH_FAR;) {
    float h = SDFAll(ro + rd * t);
    if(h < RAYMARCH_PRECISION) {
      return 0.;
    }
    t += h;
  }
  return 1.;
}

// 打光
vec3 AddLight(vec3 positon) {
  // 当前着色点的法线
  vec3 n = SDFNormal(positon);
  // 当前着色点到光源的方向
  vec3 lightDir = normalize(LIGHT_POS - positon);
  // 漫反射
  vec3 diffuse = SPHERE_KD * max(dot(lightDir, n), 0.);
  // 投影
  float shadow = Shadow(positon, normalize(LIGHT_POS - positon));
  // 在漫反射的基础上添加投影
  diffuse *= shadow * 0.5 + 0.5;

  // 环境光
  float amb = 0.2 + dot(-lightDir, n) * 0.4;
  // 最终颜色
  return diffuse + amb;
}

// 渲染
vec3 Render(vec2 coord) {
  // 光线推进的数据
  RayMarchData rm = RayMarch(CAMERA_POS, normalize(RotateMatrix() * vec3(coord, -1)));
  // 片元颜色
  vec3 color = vec3(0);
  if(rm.crash) {
    vec3 p = rm.pos;
    // 打光
    color = AddLight(p);
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
  // 最终颜色
  fragColor = vec4(color, 1);
}
