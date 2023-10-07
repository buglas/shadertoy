#define PI 3.14159265

// 坐标系缩放
#define PROJECTION_SCALE  1.

// 球体的球心位置
#define SPHERE_POS vec3(0, 0, -2)
// 球体的半径
#define SPHERE_R 1.0
// 球体的漫反射系数
#define SPHERE_KD vec3(1)

// 相机视点位
// #define CAMERA_POS vec3(1, 0, 0)

vec3 CAMERA_POS=vec3(1, 0, 0);

// 相机目标点
#define CAMERA_TARGET vec3(0, 0, -2)
// 上方向
#define CAMERA_UP vec3(0, 1, 0)

// 光线推进的起始距离 
#define RAYMARCH_NEAR 0.1
// 光线推进的最远距离
#define RAYMARCH_FAR 128.
// 光线推进次数
#define RAYMARCH_TIME 20
// 当推进后的点位距离物体表面小于RAYMARCH_PRECISION时，默认此点为物体表面的点
#define RAYMARCH_PRECISION 0.001

// 点光源位置
#define LIGHT_POS vec3(1, 1, 0)

// 相邻点的抗锯齿的行列数
#define AA 3

// 记录鼠标运动
float mx=0.;


// 鼠标旋转视点
void rotateCameraPos(){
  // 鼠标按下
  if(iMouse.z > 0. && iMouse.w > 0.){
    mx=iMouse.x;
  }
  if (iMouse.z > 0.01) {
    vec3 p=CAMERA_POS-CAMERA_TARGET;
    float theta = (iMouse.x) / iResolution.x * 4. * PI;
    float c=cos(theta);
    float s=sin(theta);
    mat3 m=mat3(
      c,0.,-s,
      0.,1.,0.,
      s,0.,c
    );
    CAMERA_POS= m*p+CAMERA_TARGET;
  }
}


// 投影坐标系
vec2 ProjectionCoord(in vec2 coord) {
  return PROJECTION_SCALE * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

//从相机视点到片元的射线
vec3 RayDir(in vec2 coord) {
  return normalize(vec3(coord, 0) - CAMERA_POS);
}

//球体的SDF模型
float SDFSphere(vec3 coord) {
  return length(coord - SPHERE_POS) - SPHERE_R;
}

// 计算球体的法线
vec3 SDFNormal(in vec3 p) {
  const float h = 0.0001;
  const vec2 k = vec2(1, -1);
  return normalize(k.xyy * SDFSphere(p + k.xyy * h) +
    k.yyx * SDFSphere(p + k.yyx * h) +
    k.yxy * SDFSphere(p + k.yxy * h) +
    k.xxx * SDFSphere(p + k.xxx * h));
}

// 打光
vec3 AddLight(vec3 positon) {
  // 当前着色点的法线
  vec3 n = SDFNormal(positon);
  // 当前着色点到光源的方向
  vec3 lightDir = normalize(LIGHT_POS - positon);
  // 漫反射
  vec3 diffuse = SPHERE_KD * max(dot(lightDir, n), 0.);
  // 环境光
  float amb = 0.15 + dot(-lightDir, n) * 0.2;
  // 最终颜色
  return diffuse + amb;
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

// 光线推进
vec3 RayMarch(vec2 coord) {
  float d = RAYMARCH_NEAR;
  // 用鼠标旋转视点
  rotateCameraPos();
  // 从相机视点到当前片元的射线
  vec3 rd = normalize(RotateMatrix() * vec3(coord, -1));
  // 片元颜色
  vec3 color = vec3(0);
  for(int i = 0; i < RAYMARCH_TIME && d < RAYMARCH_FAR; i++) {
    // 光线推进后的点位
    vec3 p = CAMERA_POS + d * rd;
    // 光线推进后的点位到球体的有向距离
    float curD = SDFSphere(p);
    // 若有向距离小于一定的精度，默认此点在球体表面
    if(curD < RAYMARCH_PRECISION) {
      color = AddLight(p);
      break;
    }
    // 距离累加
    d += curD;
  }
  return color;
}

// 抗锯齿 Anti-Aliasing
vec3 RayMarch_anti(vec2 fragCoord) {
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
      color += RayMarch(coord);
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
  vec3 color = RayMarch_anti(fragCoord);
  
  // 最终颜色
  fragColor = vec4(color, 1);
}
