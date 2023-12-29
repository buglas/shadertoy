// 贴图
#iChannel0 "file://images/bridge/posx.jpg"
#iChannel1 "file://images/bridge/negx.jpg"
#iChannel2 "file://images/bridge/posy.jpg"
#iChannel3 "file://images/bridge/negy.jpg"
#iChannel4 "file://images/bridge/posz.jpg"
#iChannel5 "file://images/bridge/negz.jpg"

// Wrap方式：Clamp Repeat  Mirror
#iChannel0::WrapMode "Repeat"

// 采样方式：Nearest Linear NearestMipMapNearest
#iChannel0::MinFilter "NearestMipMapNearest"
#iChannel0::MagFilter "Nearest"


// 坐标系缩放
#define PROJECTION_SCALE  1.

// 球体的半径
#define SPHERE_R 1.2
// 球体的球心位置
#define SPHERE_POS vec3(1.3, SPHERE_R, 0)
// 球体的漫反射系数
#define SPHERE_KD vec3(0,0.6,0.9)

// 长方体的中心位置
#define RECT_POS vec3(-1.3, 0, 0)
// 长方体的尺寸
#define RECT_SIZE vec3(.2,2.6,2.)
// 长方体的漫反射系数
#define RECT_KD vec3(1,1,0)

// 相机目标点
#define CAMERA_TARGET vec3(0, 0,0)

// 时间
#define TIME iTime*0.5
// 相机默认视点位
#define CAMERA_POS_DEFAULT vec3(3, 3, 4)
// 相机视点位，绕y轴旋转
#define CAMERA_POS mat3(cos(TIME),0,sin(TIME),0,1,0,-sin(TIME),0,cos(TIME))*(CAMERA_POS_DEFAULT-CAMERA_TARGET)+CAMERA_TARGET
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
#define LIGHT_POS vec3(4,5,3)

// 相邻点的抗锯齿的行列数
#define AA 3

// 栅格图像的z位置
#define SCREEN_Z -1.

// 要渲染的对象集合
float SDFArray[3];

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
};

// 坐标系
vec2 Coord(in vec2 coord) {
  return PROJECTION_SCALE * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

//球体的SDF模型
float SDFSphere(vec3 coord) {
  return length(coord - SPHERE_POS) - SPHERE_R;
}

// 长方体的的SDF模型
float SDFRect(vec3 coord) {
  vec3 d = abs(coord - RECT_POS) - RECT_SIZE;
  return length(max(d, 0.)) + min(max(d.x, max(d.y, d.z)), 0.);
}

// 水平面的SDF模型
float SDFPlane(vec3 coord) {
  return coord.y;
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

// 法线
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

// 棋盘格-未抗锯齿
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
  }else if(minObj == 2){
    return RECT_KD;
  }
}

// 打光
vec3 AddLight(vec3 positon,vec3 n,vec3 kd) {
  // 当前着色点到光源的方向
  vec3 lightDir = normalize(LIGHT_POS - positon);
  // 漫反射
  vec3 diffuse = kd * max(dot(lightDir, n), 0.);
  // 投影
  float shadow = SoftShadow(positon, lightDir, 8.);
  diffuse *= shadow;
  // 最终颜色
  return diffuse;
}

// 线性插值
vec2 liner(vec2 vmin,vec2 vmax,vec2 v){
  return (v-vmin)/(vmax-vmin);
}

// 球天
vec3 getTexture(vec3 n){
  vec3 absN=abs(n);

  //3个方向上的a值 
  float a1=sqrt(pow(length(n.xz),2.)/2.);
  float a2=sqrt(pow(length(n.yz),2.)/2.);
  float a3=sqrt(pow(length(n.xy),2.)/2.);

  float z=absN.z>=a1&&absN.z>a2?1.:0.;
  float y=absN.y>=a3&&absN.y>=a2?1.:0.;
  float x=absN.x>a1&&absN.x>a3?1.:0.;

  // xy面(前后的面)、xz面(上下的面)、zy面(左右的面)上的采样点
  vec2 p_xy= liner(vec2(-a1,-a2),vec2(a1,a2),n.xy); 
  vec2 p_xz= liner(vec2(-a3,-a2),vec2(a3,a2),n.xz); 
  vec2 p_zy= liner(vec2(-a1,-a3),vec2(a1,a3),n.zy); 

  vec4 textureZ=n.z>0.? texture(iChannel5, p_xy): texture(iChannel4, vec2(-p_xy.x,p_xy.y));
  vec4 textureY=n.y>0.? texture(iChannel2, vec2(-p_xz[0],p_xz[1])): texture(iChannel3,-p_xz);
  vec4 textureX=n.x>0.? texture(iChannel1,  vec2(-p_zy[0],p_zy[1])): texture(iChannel0, p_zy);

  vec3 colorZ = textureZ.rgb*z;
  vec3 colorY = textureY.rgb*y;
  vec3 colorX = textureX.rgb*x;

  return colorZ+colorY+colorX;
}

// 将RayMarch与渲染分离
RayMarchData RayMarch(vec3 ro, vec3 rd) {
  // 最近距离
  float d = RAYMARCH_NEAR;
  // 建立RayMarchData数据
  RayMarchData rm = RayMarchData(false,0,vec3(0),vec3(0),vec3(0));
  // 光线推进
  for(int i = 0; i < RAYMARCH_TIME && d < RAYMARCH_FAR; i++) {
    // 光线推进后的点位
    vec3 p = ro + d * rd;
    // 光线推进后的点位到模型的有向距离
    float curD = SDFAll(p);
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
  // 若光线没有碰触到物体，返回球天颜色
  if(!rm.crash){
    // 颜色
    rm.color=getTexture(rd);
  }
  return rm;
}

// 渲染
vec3 Render(vec3 rd) {
  // 光线推进的数据
  RayMarchData rm0 = RayMarch(CAMERA_POS, rd);
  // 初始颜色
  vec3 color=rm0.color;
  // 若初始光线碰到了球天，直接返回球天颜色
  if(!rm0.crash){
    return color;
  }
  // 光线反射的衰减系数
  float ratio=0.7;
  // 暂存数据
  vec3 curRo=rm0.ro;
  vec3 curRd=rm0.reflect;
  for(int i=0;i<4;i++){
    // 下一次RayMarch数据
    RayMarchData rmNext = RayMarch(curRo, curRd); 
    // 将当前物体的颜色和物体或球体反射的颜色融合
    color=color*(1.-ratio)+rmNext.color*(ratio+0.2);
    if(rmNext.crash){
      curRo=rmNext.ro;
      curRd=rmNext.reflect;
      ratio*=ratio;
    }else{
      break;
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
      vec2 coord = Coord(fragCoord + offset);
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
