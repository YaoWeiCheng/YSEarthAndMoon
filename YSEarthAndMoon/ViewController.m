//
//  ViewController.m
//  YSEarthAndMoon
//
//  Created by CYW on 2019/2/1.
//  Copyright © 2019 cyw. All rights reserved.
//

#import "ViewController.h"

#import "AGLKVertexAttribArrayBuffer.h"
#import "sphere.h"

//场景地球轴倾斜度
static const GLfloat SceneEarthAxialTiltDeg = 23.5f;
//月球轨道日数
static const GLfloat SceneDaysPerMoonOrbit = 28.0f;
//半径
static const GLfloat SceneMoonRadiusFractionOfEarth = 0.25;
//月球距离地球的距离
static const GLfloat SceneMoonDistanceFromEarth = 2.0f;


@interface ViewController ()
@property(nonatomic,strong)EAGLContext *mContext;

//顶点positionBuffer
@property(nonatomic,strong)AGLKVertexAttribArrayBuffer *vertexPositionBuffer;

//顶点NormalBuffer
@property(nonatomic,strong)AGLKVertexAttribArrayBuffer *vertexNormalBuffer;

//顶点TextureCoordBuffer
@property(nonatomic,strong)AGLKVertexAttribArrayBuffer *vertextTextureCoordBuffer;

//光照、纹理
@property(nonatomic,strong)GLKBaseEffect *baseEffect;

//不可变纹理对象数据,地球纹理对象
@property(nonatomic,strong)GLKTextureInfo *earchTextureInfo;

//月亮纹理对象
@property(nonatomic,strong)GLKTextureInfo *moomTextureInfo;

//模型视图矩阵
//GLKMatrixStackRef CFType 允许一个4*4 矩阵堆栈
@property(nonatomic,assign)GLKMatrixStackRef modelViewMatrixStack;

//地球的旋转角度
@property(nonatomic,assign)GLfloat earthRotationAngleDegress;
//月亮旋转的角度
@property(nonatomic,assign)GLfloat moonRotationAngleDegress;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1.新建OpenGL ES 上下文
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //2.获取GLKView
    GLKView *view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24; //设置深度缓冲区的格式
    
    [EAGLContext setCurrentContext:self.mContext];
    
    //开启深度测试
    glEnable(GL_DEPTH_TEST);
    
    //3.创建GLKBaseEffect 光照信息
    self.baseEffect = [[GLKBaseEffect alloc] init];
    
    //配置baseEffect光照信息
    [self configureLight];
    
    //获取屏幕纵横比
    GLfloat aspectRatio = self.view.frame.size.width / self.view.frame.size.height;
    
    //4.创建投影矩阵 -> 透视投影矩阵
    self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(-1.0f * aspectRatio, 1.0f * aspectRatio, -1.0, 1.0, 1.0, 120.0f);
    
    //5.设置模型矩形 -5.0f 表示往屏幕内移动-5.0f距离
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -5.0f);
    
    //6.设置清屏颜色
    GLKVector4 colorVector4 = GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f);
    [self setClearColor:colorVector4];
    
    //7.顶点数组
    [self bufferData];
}

-(void)bufferData
{
    //1、GLKMatrixStackCreate()创建一个新的空矩阵
    self.modelViewMatrixStack = GLKMatrixStackCreate(kCFAllocatorDefault);
    
    //2、为将要缓存区数据开辟空间
    //sphereVerts 在sphere.h文件中存在
    /*
     参数1：数据大小 3个GLFloat类型，x,y,z
     参数2：有多少个数据，count
     参数3：数据大小
     参数4：用途 GL_STATIC_DRAW，
     */
    //顶点数据缓存，顶点数据从sphere.h文件的sphereVerts数组中获取顶点数据x,y,z
    self.vertexPositionBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:(3 * sizeof(GLfloat)) numberOfVertices:sizeof(sphereVerts)/(3 * sizeof(GLfloat)) bytes:sphereVerts usage:GL_STATIC_DRAW];
    
    //法线，光照坐标 sphereNormals数组 x,y,z
    self.vertexNormalBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:(3 * sizeof(GLfloat)) numberOfVertices:sizeof(sphereNormals)/(3 * sizeof(GLfloat)) bytes:sphereNormals usage:GL_STATIC_DRAW];
    
    //纹理坐标 sphereTexCoords数组 x,y
    self.vertextTextureCoordBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:(2 * sizeof(GLfloat)) numberOfVertices:sizeof(sphereTexCoords)/ (2 * sizeof(GLfloat)) bytes:sphereTexCoords usage:GL_STATIC_DRAW];
    
    
    //3.获取地球纹理
    CGImageRef earthImageRef = [UIImage imageNamed:@"Earth512x256.jpg"].CGImage;
    
    //控制图像加载方式的选项
    NSDictionary *earthOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],GLKTextureLoaderOriginBottomLeft, nil];
    
    //将纹理图片加载到纹理数据对象earchTextureInfo中
    /*
     参数1:加载的纹理图片
     参数2:控制图像加载的方式的选项-字典
     参数3:错误信息
     */
    self.earchTextureInfo = [GLKTextureLoader textureWithCGImage:earthImageRef options:earthOptions error:NULL];
    
    //4.获取月亮纹理
    CGImageRef moonImageRef = [UIImage imageNamed:@"Moon256x128"].CGImage;
    
    NSDictionary *moonOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],GLKTextureLoaderOriginBottomLeft, nil];
    
    self.moomTextureInfo = [GLKTextureLoader textureWithCGImage:moonImageRef options:moonOptions error:NULL];
    
    //矩阵堆
    //用所提供的矩阵替换最顶层矩阵,将self.baseEffect.transform.modelviewMatrix,替换self.modelViewMatrixStack
    GLKMatrixStackLoadMatrix4(self.modelViewMatrixStack, self.baseEffect.transform.modelviewMatrix);
    
    //初始化在轨道上月球位置
    self.moonRotationAngleDegress = -20.0f;
    
    
}


-(void)setClearColor:(GLKVector4)clearColorRGBA
{
    glClearColor(clearColorRGBA.r, clearColorRGBA.g, clearColorRGBA.b, clearColorRGBA.a);
}

-(void)configureLight
{
    //开启light0光照
    self.baseEffect.light0.enabled = GL_TRUE;
    
    /*
     union _GLKVector4
     {
     struct { float x, y, z, w; };
     struct { float r, g, b, a; };
     struct { float s, t, p, q; };
     float v[4];
     } __attribute__((aligned(16)));
     typedef union _GLKVector4 GLKVector4;
     
     union共用体
     有3个结构体，
     比如表示顶点坐标的x,y,z,w
     比如表示颜色的，RGBA;
     表示纹理的stpq
     
     */
    //2.设置漫射光颜色,分别是red，green，blue，alpha
    self.baseEffect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    
    /*
     The position of the light in world coordinates.
     世界坐标中的光的位置。
     If the w component of the position is 0.0, the light is calculated using the directional light formula. The x, y, and z components of the vector specify the direction the light shines. The light is assumed to be infinitely far away; attenuation and spotlight properties are ignored.
     如果位置的w分量为0，则使用定向光公式计算光。向量的x、y和z分量指定光的方向。光被认为是无限远的，衰减和聚光灯属性被忽略。
     If the w component of the position is a non-zero value, the coordinates specify the position of the light in homogenous coordinates, and the light is either calculated as a point light or a spotlight, depending on the value of the spotCutoff property.
     如果该位置的W组件是一个非零的值，指定的坐标的光在齐次坐标的位置，和光是一个点光源和聚光灯计算，根据不同的spotcutoff属性的值
     The default value is [0.0, 0.0, 1.0, 0.0].
     默认值[0.0f,0.0f,1.0f,0.0f];
     */
    //灯光位置
    self.baseEffect.light0.position = GLKVector4Make(1.0f, 0.0f, 0.2f, 0.0f);
    
    //光的环境部分,分别是red，green，blue，alpha
    self.baseEffect.light0.ambientColor = GLKVector4Make(0.2, 0.2, 0.2, 1.0f);
    
}

#pragma mark - drawRect
//渲染场景
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //设置清屏颜色
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    
    //清空颜色缓存区和深度缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //地球旋转角度
    _earthRotationAngleDegress += 360.0f/60.0f;
    //月球旋转角度
    _moonRotationAngleDegress += (360.0f/60.0f)/SceneDaysPerMoonOrbit;
    
    //2、准备绘制
    /*
     其实就是把数据传递过去，然后指定读取方式
     参数1：数据是做什么用的
     参数2：数据读取个数
     参数3：数据读取索引
     参数4：是否调用glEnableVertexAttribArray
     
     着色器能否读取到数据，由是否启用了对应的属性决定，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。
     
     
     默认情况下，出于性能考虑，所有顶点着色器的属性（Attribute）变量都是关闭的，意味着数据在着色器端是不可见的，哪怕数据已经上传到GPU，由glEnableVertexAttribArray启用指定属性，才可在顶点着色器中访问逐顶点的属性数据。glVertexAttribPointer或VBO只是建立CPU和GPU之间的逻辑连接，从而实现了CPU数据上传至GPU。但是，数据在GPU端是否可见，即，着色器能否读取到数据，由是否启用了对应的属性决定，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。
     
     那么，glEnableVertexAttribArray应该在glVertexAttribPointer之前还是之后调用？答案是都可以，只要在绘图调用（glDraw*系列函数）前调用即可。
     */
    [self.vertexPositionBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
    [self.vertexNormalBuffer prepareToDrawWithAttrib:GLKVertexAttribNormal numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
    [self.vertextTextureCoordBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0 numberOfCoordinates:2 attribOffset:0 shouldEnable:YES];
    
    //3.开始绘制
    [self drawEarth];
    [self drawMoon];
}


-(void)drawEarth
{
    //获取纹理的name、target
    self.baseEffect.texture2d0.name = self.earchTextureInfo.name;
    self.baseEffect.texture2d0.target = self.earchTextureInfo.target;
    
    /*
     current matrix:
     1.000000 0.000000 0.000000 0.000000
     0.000000 1.000000 0.000000 0.000000
     0.000000 0.000000 1.000000 0.000000
     0.000000 0.000000 -5.000000 1.000000
     
     为什么？因为你在viewDidLoad中设置的
     //5.设置模型矩形 -5.0f表示往屏幕内移动-5.0f距离
     self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -5.0f);
     */
    //将当前的modelViewMatrixStack 压栈
    GLKMatrixStackPush(self.modelViewMatrixStack);
    
    //在指定的轴上旋转最上面的矩阵,围绕x轴旋转
    GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(SceneEarthAxialTiltDeg), 1.0f, 0.0f, 0.0f);
    
    /*
     current matrix:
     1.000000 0.000000 0.000000 0.000000
     0.000000 0.917060 0.398749 0.000000
     0.000000 -0.398749 0.917060 0.000000
     0.000000 0.000000 -5.000000 1.000000
     
     为什么？
     将矩阵与围绕X旋转的旋转矩阵相乘，即可得上述结果
     */
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
    
    //准备绘制
    [self.baseEffect prepareToDraw];
    
    //调用AGLKVertexAttribArrayBuffer，绘制图形
    /*
     参数1：绘制的方式，三角形
     参数2：绘制数据读取的索引
     参数3：绘制数据的大小
     */
    [AGLKVertexAttribArrayBuffer drawPreparedArraysWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sphereNumVerts];
    
    //绘制完毕，则出栈
    /*
     current matrix:
     0.994522 0.041681 -0.095859 0.000000
     0.000000 0.917060 0.398749 0.000000
     0.104528 -0.396565 0.912036 0.000000
     0.000000 0.000000 -5.000000 1.000000
     */
    GLKMatrixStackPop(self.modelViewMatrixStack);
    
    /*
     current matrix:
     1.000000 0.000000 0.000000 0.000000
     0.000000 1.000000 0.000000 0.000000
     0.000000 0.000000 1.000000 0.000000
     0.000000 0.000000 -5.000000 1.000000
     */
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
    
}

-(void)drawMoon
{
    //获取纹理的name、target
    self.baseEffect.texture2d0.name = self.moomTextureInfo.name;
    self.baseEffect.texture2d0.target = self.moomTextureInfo.target;
    
    //压栈
    GLKMatrixStackPush(self.modelViewMatrixStack);
    
    //围绕Y轴旋转moonRotationAngleDegress角度
    //自转
    GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(self.moonRotationAngleDegress), 0.0f, 1.0f, 0.0f);
    
    //平移 - 月球距离地球的距离
    GLKMatrixStackTranslate(self.modelViewMatrixStack, 0.0f, 0.0f, SceneMoonDistanceFromEarth);
    
    //缩放，把月球缩放
    GLKMatrixStackScale(self.modelViewMatrixStack, SceneMoonRadiusFractionOfEarth, SceneMoonRadiusFractionOfEarth, SceneMoonRadiusFractionOfEarth);
    
    //旋转 围绕Y轴旋转
    GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(self.moonRotationAngleDegress), 0.0f, 1.0f, 0.0f);
    
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
    
    [self.baseEffect prepareToDraw];
    
    [AGLKVertexAttribArrayBuffer drawPreparedArraysWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sphereNumVerts];
    
    //设置完毕出栈
    GLKMatrixStackPop(self.modelViewMatrixStack);
    
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
    
}


#pragma mark -Switch Click
//切换正投影效果或透视投影效果
- (IBAction)switchClick:(UISwitch *)sender {
    
    GLfloat aspect = self.view.bounds.size.width / self.view.bounds.size.height;
    
    if ([sender isOn]) {
        
        //正投影
        self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeFrustum(-1.0f * aspect, 1.0f * aspect, -1.0, 1.0, 2.0f, 120.0);
        
    }else {
        
        //透视投影
        self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(-1.0f * aspect, 1.0f * aspect, -1.0, 1.0, 2.0f, 120.0);
    }
}

//横屏处理
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    
    return (toInterfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown &&
            toInterfaceOrientation !=
            UIInterfaceOrientationPortrait);
    
}

@end
