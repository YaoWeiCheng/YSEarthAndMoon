//
//  AGLKVertexAttribArrayBuffer.m
//  
//

#import "AGLKVertexAttribArrayBuffer.h"

@interface AGLKVertexAttribArrayBuffer ()

@property (nonatomic, assign) GLsizeiptr
   bufferSizeBytes;

@property (nonatomic, assign) GLsizeiptr
   stride;

@end


@implementation AGLKVertexAttribArrayBuffer

@synthesize name;
@synthesize bufferSizeBytes;
@synthesize stride;


/////////////////////////////////////////////////////////////////
// 此方法在当前的OpenGL ES上下文中创建一个顶点属性数组缓冲区，用于调用此方法的线程.
- (id)initWithAttribStride:(GLsizeiptr)aStride
   numberOfVertices:(GLsizei)count
   bytes:(const GLvoid *)dataPtr
   usage:(GLenum)usage;
{
   NSParameterAssert(0 < aStride);
   NSAssert((0 < count && NULL != dataPtr) ||
      (0 == count && NULL == dataPtr),
      @"data must not be NULL or count > 0");
      
   if(nil != (self = [super init]))
   {
      stride = aStride;
      bufferSizeBytes = stride * count;
      // 第一步
      glGenBuffers(1,
         &name);
      // 第二步
      glBindBuffer(GL_ARRAY_BUFFER,
         self.name);
       
      // 第三步
      glBufferData(
         GL_ARRAY_BUFFER,  // 初始化缓存区的内容
         bufferSizeBytes,  // 要复制的字节数
         dataPtr,          // 要复制的字节地址
         usage);           //GPU内存中的缓存
         
      NSAssert(0 != name, @"Failed to generate name");
   }
   
   return self;
}   


// 此方法加载由接收器存储的数据
- (void)reinitWithAttribStride:(GLsizeiptr)aStride
   numberOfVertices:(GLsizei)count
   bytes:(const GLvoid *)dataPtr;
{
   NSParameterAssert(0 < aStride);
   NSParameterAssert(0 < count);
   NSParameterAssert(NULL != dataPtr);
   NSAssert(0 != name, @"Invalid name");

   self.stride = aStride;
   self.bufferSizeBytes = aStride * count;
   
    // 第二步
   glBindBuffer(GL_ARRAY_BUFFER,
      self.name);
    // 第三步
   glBufferData(
      GL_ARRAY_BUFFER,  
      bufferSizeBytes,  
      dataPtr,
      GL_DYNAMIC_DRAW); 
}



// 当应用程序希望使用缓冲区呈现任何几何图形时，必须准备一个顶点属性数组缓冲区。当你的应用程序准备一个缓冲区时，一些OpenGL ES状态被改变，允许绑定缓冲区和配置指针。
- (void)prepareToDrawWithAttrib:(GLuint)index
   numberOfCoordinates:(GLint)count
   attribOffset:(GLsizeiptr)offset
   shouldEnable:(BOOL)shouldEnable
{
   NSParameterAssert((0 < count) && (count < 4));
   NSParameterAssert(offset < self.stride);
   NSAssert(0 != name, @"Invalid name");

   glBindBuffer(GL_ARRAY_BUFFER,
      self.name);

   if(shouldEnable)
   {
       glEnableVertexAttribArray(index);
   }

   glVertexAttribPointer( 
      index,            
      count,            
      GL_FLOAT,         
      GL_FALSE,         
      self.stride,      
      NULL + offset);
    
#ifdef DEBUG
   {
      GLenum error = glGetError();
      if(GL_NO_ERROR != error)
      {
         NSLog(@"GL Error: 0x%x", error);
      }
   }
#endif
}

// 提交由模式标识的绘图命令，并指示OpenGL ES从索引的顶点开始从缓冲区中使用计数顶点。顶点索引从0开始
- (void)drawArrayWithMode:(GLenum)mode
   startVertexIndex:(GLint)first
   numberOfVertices:(GLsizei)count
{
   NSAssert(self.bufferSizeBytes >= 
      ((first + count) * self.stride),
      @"Attempt to draw more vertex data than available.");
      
   glDrawArrays(mode, first, count); // Step 6
}



// 提交由模式标识的绘图命令，并指示OpenGL ES从准备好的缓冲区中的顶点开始，从先前准备好的缓冲区中使用计数顶点。
+ (void)drawPreparedArraysWithMode:(GLenum)mode
   startVertexIndex:(GLint)first
   numberOfVertices:(GLsizei)count;
{
   glDrawArrays(mode, first, count);
}


// 此方法删除接收缓冲区的当前上下文接收器时释放。
- (void)dealloc
{
   
    if (0 != name)
    {
        glDeleteBuffers (1, &name);  
        name = 0;
    }
}

@end
