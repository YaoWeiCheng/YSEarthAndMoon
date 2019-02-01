//
//  AGLKVertexAttribArrayBuffer.h
//  
//

#import <GLKit/GLKit.h>

@class AGLKElementIndexArrayBuffer;


typedef enum {
    AGLKVertexAttribPosition = GLKVertexAttribPosition,
    AGLKVertexAttribNormal = GLKVertexAttribNormal,
    AGLKVertexAttribColor = GLKVertexAttribColor,
    AGLKVertexAttribTexCoord0 = GLKVertexAttribTexCoord0,
    AGLKVertexAttribTexCoord1 = GLKVertexAttribTexCoord1,
} AGLKVertexAttrib;


@interface AGLKVertexAttribArrayBuffer : NSObject
{
   GLsizeiptr   stride;
   GLsizeiptr   bufferSizeBytes;
   GLuint       name;
}

//GLsizeiptr 其实就是long类型
//GLsizei 就是int32_t,其实就是int类型

@property (nonatomic, readonly) GLuint
   name;
@property (nonatomic, readonly) GLsizeiptr
   bufferSizeBytes;
@property (nonatomic, readonly) GLsizeiptr
   stride;


//绘制
+ (void)drawPreparedArraysWithMode:(GLenum)mode
   startVertexIndex:(GLint)first
   numberOfVertices:(GLsizei)count;

//创建顶点缓存数组
- (id)initWithAttribStride:(GLsizeiptr)stride
   numberOfVertices:(GLsizei)count
   bytes:(const GLvoid *)dataPtr
   usage:(GLenum)usage;

//分配顶点数据，准备绘制
- (void)prepareToDrawWithAttrib:(GLuint)index
   numberOfCoordinates:(GLint)count
   attribOffset:(GLsizeiptr)offset
   shouldEnable:(BOOL)shouldEnable;

//绘制
- (void)drawArrayWithMode:(GLenum)mode
   startVertexIndex:(GLint)first
   numberOfVertices:(GLsizei)count;

//重新缓存顶点数组
- (void)reinitWithAttribStride:(GLsizeiptr)stride
   numberOfVertices:(GLsizei)count
   bytes:(const GLvoid *)dataPtr;
   
@end
