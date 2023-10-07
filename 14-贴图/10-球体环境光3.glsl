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

// 相机视点位
#define CAMERA_POS mat3(cos(iTime),0,sin(iTime),0,1,0,-sin(iTime),0,cos(iTime))*(vec3(0, 0, 0.4))

// 相机目标点
#define CAMERA_TARGET vec3(0)
// 上方向
#define CAMERA_UP vec3(0, 1, 0)

// 坐标系
vec2 Coord(in vec2 coord) {
  return PROJECTION_SCALE * 2. * (coord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
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

// 线性插值
vec2 liner(vec2 vmin,vec2 vmax,vec2 v){
  return (v-vmin)/(vmax-vmin);
}

// 获取纹理
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

/* 绘图函数，画布中的每个片元都会执行一次，执行方式是并行的。
fragColor 输出参数，用于定义当前片元的颜色。
fragCoord 输入参数，当前片元的位置，原点在画布左下角，右侧边界为画布的像素宽，顶部边界为画布的像素高
*/
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec3 rd = normalize(RotateMatrix() * vec3(Coord(fragCoord), -1));
  vec3 color =getTexture(rd);
  fragColor = vec4(color, 1);
}