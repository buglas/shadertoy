// 坐标系缩放
#define PROJECTION_SCALE  1.

// 球体的半径
#define SPHERE_R 1.2
// 球体的球心位置
#define SPHERE_POS vec3(0, SPHERE_R, -4)
// 球体的漫反射系数
// #define SPHERE_KD vec3(1,0,0.5)
#define SPHERE_KD vec3(0,0.72,1)

// 相机视点位
#define CAMERA_POS vec3(2, 3, 0)
// 相机目标点
#define CAMERA_TARGET vec3(0, 0.6, -4)
// 上方向
#define CAMERA_UP vec3(0, 1, 0)

//基向量c，视线
#define C normalize(CAMERA_POS - CAMERA_TARGET)
//基向量a，视线和上方向的垂线
#define A cross(CAMERA_UP, C)
//基向量b，修正上方向
#define B cross(C, A)
// 相机旋转矩阵
#define  CAMERA_ROTATE mat3(A,B,C)

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

// 玻璃折射率
#define GLASS_REFRACTIVITY 1.5
#define GLASS_REFRACTIVITY_INVERT 1./GLASS_REFRACTIVITY

// 要渲染的对象集合
float SDFArray[2];

/* 
距离场最小的物体:
0 地面
1 球体
 */
int minObj = 0;


// RayMarch 数据的结构体
struct RayMarchData {
  // 是否碰撞到物体  
  bool crash;
  // 射线碰撞到的物体
  int obj;
  // 射线碰撞到的着色点位置
  vec3 ro;
  // 射线碰撞到着色点时的反射方向
  vec3 reflect;
  // 射线碰撞到的着色点的颜色
  vec3 color; 
  // 法线
  vec3 normal;
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

// 所有的SDF模型
float SDFAll(vec3 coord) {
  SDFArray[0] = SDFPlane(coord);
  SDFArray[1] = SDFSphere(coord);
  
  float min = SDFArray[0];
  minObj = 0;
  if(SDFArray[1]<SDFArray[0]){
    min = SDFArray[1];
    minObj = 1;
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


// 棋盘格
float Checkers(in vec2 uv) {
  vec2 grid = floor(uv*2.);
  return mod(grid.x + grid.y, 2.);
}

// 获取漫反射系数
vec3 getKD(vec3 pos){
  if(minObj == 0) {
    float check = Checkers(pos.xz);
    return vec3(check * 0.8 + 0.2);
  } else if(minObj == 1) {
    return SPHERE_KD;
  }
}

// 打光
vec3 AddLight(vec3 positon,vec3 n,vec3 kd) {
  // 当前着色点到光源的方向
  vec3 lightDir = normalize(LIGHT_POS - positon);
  // 漫反射
  vec3 diffuse = kd * max(dot(lightDir, n), 0.);
  // 投影
  float shadow = SoftShadow(positon, lightDir, 16.);
  diffuse *= shadow+0.25;
  // 最终颜色
  return diffuse;
}

// 根据索引计算SDF
float getSDFbyInd(int ind,vec3 p){
  if(ind==0){
    return SDFPlane(p);
  }else if(ind==1){
    return SDFSphere(p);
  }else{
    return SDFAll(p);
  }
}

// 将RayMarch与渲染分离
RayMarchData RayMarch(vec3 ro, vec3 rd,int curSDF) {
  // 最近距离
  float d = RAYMARCH_NEAR;
  // 建立RayMarchData数据
  RayMarchData rm;
  rm = RayMarchData(false,0,vec3(0),vec3(0),vec3(0),vec3(0));
  for(int i = 0; i < RAYMARCH_TIME && d < RAYMARCH_FAR; i++) {
    // 光线推进后的点位
    vec3 p = ro + d * rd;
    // 光线推进后的点位到模型的有向距离
    float curD = getSDFbyInd(curSDF,p);
    curD=abs(curD);
    // 若有向距离小于一定的精度，默认此点在模型表面
    if(curD < RAYMARCH_PRECISION) {
      // 发生碰撞
      rm.crash=true;
      // 碰撞到的物体
      rm.obj=minObj;
      // 光源
      rm.ro=p;
      // 当前着色点的法线
      vec3 n = SDFNormal(p);
      rm.normal=n;
      // 光线反射方向
      rm.reflect=reflect(rd,n);
      // 碰到的着色点的漫反射系数
      vec3 kd=getKD(p);
      // 碰到的着色点的颜色
      rm.color=AddLight(p,n,kd);
      break;
    }
    // 距离累加
    d += curD;
  }
  return rm;
}

// 渲染
vec3 Render(vec3 rd) {
  // 初始RayMarch数据,可以打到球体和平面表面
  RayMarchData rm0 = RayMarch(CAMERA_POS, rd,-1);
  // 颜色
  vec3 color=rm0.color;
  // 球体
  if(rm0.crash&&rm0.obj==1){
    // 光线反射的衰减系数
    float ratio0=0.7;
    float ratio1=1.-ratio0;

    // 计算光线进入球体时的入射方向
    vec3 incidentDir=refract(rm0.reflect,rm0.normal,GLASS_REFRACTIVITY_INVERT);
    // 基于入射方向，在球体内部追踪球体
    RayMarchData rm1 = RayMarch(rm0.ro, incidentDir,1);
    if(rm1.crash){
      // 计算光线出球体时的出射方向
      vec3 outDir=refract(rm1.reflect,rm1.normal,GLASS_REFRACTIVITY);
      // 基于出射方向，追踪平面
      RayMarchData rm2 = RayMarch(rm1.ro, outDir,0);
      if(rm2.crash){
        // 折射颜色
        color=color*ratio1+rm2.color*color;
      }
    }

    // 反射
    RayMarchData rmNext = RayMarch(rm0.ro, rm0.reflect,-1); 
    if(rmNext.crash){
      // 在折射颜色的基础上，合成反射颜色
      color=color*ratio1+rmNext.color*ratio0;
    }
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
      // 光线推进的方向
      vec3 rd = normalize(CAMERA_ROTATE * vec3(coord, SCREEN_Z));
      // 累加周围片元的颜色
      color += Render(rd);
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
