// 坐标系缩放
#define PROJECTION_SCALE  1.

// 球体的球心位置
#define SPHERE_POS vec3(1, 1, -4)
// 球体的半径
#define SPHERE_R 1.0
// 球体的漫反射系数
#define SPHERE_KD vec3(0,0.6,0.9)

// 长方体的中心位置
#define RECT_POS vec3(-1, 1, -4)
// 长方体的尺寸
#define RECT_SIZE vec3(.5,1,1)
// 长方体的漫反射系数
#define RECT_KD vec3(1,1,0)

// 相机视点位
#define TIME iTime*0.5
#define CAMERA_POS mat3(cos(TIME),0,sin(TIME),0,1,0,-sin(TIME),0,cos(TIME))*(vec3(2, 3, 0)-vec3(0,0,-4))+vec3(0,0,-4)
// 相机目标点
#define CAMERA_TARGET vec3(0, 0, -4)
// 上方向
#define CAMERA_UP vec3(0, 1, 0)

// 光线推进的起始距离 
#define RAYMARCH_NEAR 0.1
// 光线推进的最远距离
#define RAYMARCH_FAR 64.
// 光线推进次数
#define RAYMARCH_TIME 128
// 当推进后的点位距离物体表面小于RAYMARCH_PRECISION时，默认此点为物体表面的点
#define RAYMARCH_PRECISION 0.001 

// 点光源位置
#define LIGHT_POS vec3(4,5, -3)

// 相邻点的抗锯齿的行列数
#define AA 3

// 栅格图像的z位置
#define SCREEN_Z -1.

/* 
距离场最小的对象:
0 地面
1 球体
2 长方体
 */
int minObj = 0;

// 要渲染的对象集合
float SDFArray[3];

// 光线推进数据的结构体
struct RayMarchData {
  vec3 pos;
  bool crash;
};

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

// 长方体的的SDF模型
float SDFRect(vec3 coord) {
  vec3 d = abs(coord - RECT_POS) - RECT_SIZE;
  return length(max(d, 0.)) + min(max(d.x, max(d.y, d.z)), 0.);
}

// 所有的SDF模型
float SDFAll(vec3 coord) {
  SDFArray[0] = SDFPlane(coord);
  SDFArray[1] = SDFSphere(coord);
  SDFArray[2] = SDFRect(coord);

  float min = SDFArray[0];
  minObj = 0;
  for(int i = 1; i < 3; i++) {
    if(min > SDFArray[i]) {
      min = SDFArray[i];
      minObj = i;
    }
  }
  return min;
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

// 软投影
float SoftShadow(in vec3 ro, in vec3 rd, float k) {
  float res = 1.;
  for(float t = RAYMARCH_NEAR; t < RAYMARCH_FAR;) {
    float h = SDFAll(ro + rd * t);
    if(h < RAYMARCH_PRECISION) {
      return 0.;
    }
    res = min(res, k * h / t);
    t += h;
  }
  return res;
}

// 打光
vec3 AddLight(vec3 positon, vec3 kd) {
  // 当前着色点的法线
  vec3 n = SDFNormal(positon);
  // 当前着色点到光源的方向
  vec3 lightDir = normalize(LIGHT_POS - positon);
  // 漫反射
  vec3 diffuse = kd * max(dot(lightDir, n), 0.);
  // 投影
  // float shadow = Shadow(positon, lightDir);
  float shadow = SoftShadow(positon, lightDir, 8.);
  diffuse *= shadow;

  // 环境光
  vec3 amb = kd * (0.4 + max(dot(-lightDir, n), 0.) * 0.3);

  // 最终颜色
  return diffuse + amb;
}

// 三角形分段函数
vec2 Triangle(in vec2 x) {
  vec2 h = fract(x * .5) - .5;
  return 1. - 2. * abs(h);
}

// 棋盘格
float CheckersGrad(in vec2 uv, in vec2 ddx, in vec2 ddy) {
  // 模糊力度
  // vec2 w = max(abs(ddx), abs(ddy)) + .001;
  // 强化模糊
  vec2 w = max(abs(ddx), abs(ddy)) * 4. + .001;
  // 三角形分段函数的导数
  vec2 i = (Triangle(uv + 0.5 * w) - Triangle(uv - 0.5 * w)) / w;   
  // xor 
  return 0.5 - 0.5 * i.x * i.y;
}

// 渲染
vec3 Render(vec2 coord, vec2 px, vec2 py) {
  // 相机的旋转矩阵
  mat3 rotateMatrix = RotateMatrix();
  // 光线推进的方向
  vec3 rd = normalize(rotateMatrix * vec3(coord, SCREEN_Z));
  // 光线推进的数据
  RayMarchData rm = RayMarch(CAMERA_POS, rd);
  // 片元颜色
  vec3 color = vec3(0);
  if(rm.crash) {
    // 光线推进位置
    vec3 pos = rm.pos;
    // 漫反射系数
    vec3 kd = vec3(0);
    if(minObj == 0) {
      //将px、py变换至相机世界
      vec3 rdx = normalize(rotateMatrix * vec3(px, SCREEN_Z));
      vec3 rdy = normalize(rotateMatrix * vec3(py, SCREEN_Z));
      // 将栅格图像上一个像素的偏移向量转换为棋盘格水平空间内的向量
      vec3 ddx = rd / rd.y - rdx / rdx.y;
      vec3 ddy = rd / rd.y - rdy / rdy.y;
      float check = CheckersGrad(pos.xz, ddx.xz, ddy.xz);
      kd = vec3(check * 0.8 + 0.2);
    } else if(minObj == 1) {
      kd = SPHERE_KD;
    } else if(minObj == 2) {
      kd = RECT_KD;
    }

    // 打光
    color = AddLight(pos, kd);
  }
  return color;
}

// 抗锯齿 Anti-Aliasing
vec3 Render_anti(vec2 fragCoord, vec2 px, vec2 py) {
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
      color += Render(coord, px, py);
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
  //栅格图像右偏移一个像素
  vec2 px = ProjectionCoord(fragCoord + vec2(1., 0.));
  //栅格图像左偏移一个像素
  vec2 py = ProjectionCoord(fragCoord + vec2(0., 1.));
  // 光线推进
  vec3 color = Render_anti(fragCoord, px, py);
  // 最终颜色
  fragColor = vec4(color, 1);
}
