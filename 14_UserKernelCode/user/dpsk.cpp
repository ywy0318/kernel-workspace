#include <iostream>
#include <stdlib>
#include <ctring>
#include <memory>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>
#include <vector>
#include <unordered_map>
#include <map>
#include <atomic>
#include <functional>
#include <string>

//==========模拟GPU基础设施
//模拟显存分配
void* SimMalloc(size_t size)
{
    void* ptr = std::malloc(size);
    std::cout<<"[SimGpu]模拟显存分配："<< size << "字节,地址"<<ptr <<"\n";
    return ptr;
}
void SimFree(void* ptr)
{
    std::cout<<"[SimGPU] 模拟显存释放,地址："<<ptr<<"\n";
    std::free(ptr);
}
/*
P0最高：RAII
图表学习目标：能用std::unique_ptr 和自定义析构函数，写出来永不内存泄漏的代码；
GPU模拟场景：管理模拟显存的生命周期，即使发生异常，离开作用域也能自动释放；
*/
// [RALL 模拟显存类]
class SimDeviceBuffer
{
    void* ptr_ = nullptr;
    size_t size_ = 0;
public:
    explicit SimDeivceBuffer(size_t size):size_(size)
    {
        ptr_ = SimMalloc(size);
    }
    ~SimDeviceBuffer()
    {
        if(ptr)
        {
            SimFree(ptr_);
        }
    }
    //
    SimDeviceBuffer(const SimDeviceBuffer&) = delete;
    SimDeviceBuffer& operator=(const SimDeviceBuffer&) = delete;
    void* get() const{return ptr_;}
};
void testRAII()
{
    std::cout <<"===P0 RAII 示例\n ";
    try
    {
        SimDeviceBuffer buffer(1024);
        //假设这里发生了异常
        //throw std::runtime_error("模拟异常");
        //
    }
    catch(const std::exception& e)
    {
        std::cerr << e.what() << '\n';
        //即使发生异常，buffer 的析构函数,也会被调用，自动释放显存；
    }
    std::cout<<"testRAII 执行完毕,buffer已自动释放\n\n";
}
/*
P0最高:智能指针
图表学习目标：分清 unique_ptr 和 shared_ptr的使用场景,理解weak_ptr解决循环引用;
GPU模拟场景:
1.unique_ptr独占管理一个模拟Stream(流)；
2.shared_ptr多个模拟kernel 共享同一块显存；
3.weak_ptr打破模拟Stream 与kernel之间循环引用；
*/
//模拟Stream
struct SimStream{
    int id;
    SimStream(int i):id(i) {std::count<<"[SimGpu] Stream"<< id <<"创建\n"; }
    ~SimStream() {std::cout<<"[SimGpu] Stream" << id << "销毁\n"; }
};
//模拟Kernel (任务)
struct SimKernel{
    std::string name;//
    std::shared_ptr<SimDeviceBuffer> buffer;//共享缓冲区
    std::weak_ptr<SimDeviceBuffer> stream;//弱引用打破循环
    SimKernel(std::string n,std::shared_ptr<SimDeviceBuffer> b):name(n),buffer(b)
    {}
    ~SimKernel(){std::cout <<"[SimGPU] Kernel "<<name <<"销毁\n"};
};
void testSmartPointers()
{
    std::cout<<"====P0 智能指针示例===\n";
    //1.unique_ptr 独占 stream
    std::unique_ptr<Simstream> stream = std::make_unique<SimStream>(1);

    //2.shared_ptr 共享显存
    std::shared_ptr<SimDeviceBuffer> sharedBuf = std::make_shared<SimDeviceBuffer>(2048);

    //3.多个kernel 共享同一个显存
    auto kernel1 = std::make_shared<SimKernel>("VevAdd",sharedBuf);
    auto kernel2 = std::make_shared<Simkernel>("VecMul",sharedBuf);
    //weak_ptr 绑定
    kernel1->stream = stream;
    kernel2->stream = stream;
    std::cout<<"共享显存引用计数："<<sharedBuf.user_count()<<"\n";
    std::cout<<"\n";
}
/*
P1高：移动语义
图表学习目标:理解std::move,能写出利用移动语义的容器和资源管理类，
GPU模拟场景：模拟显存对象只移动不拷贝(拷贝显存代价极高,移动只需转移指针,O(1)复杂度)
*/
class SimMoveableBuffer
{
    void* ptr_ = nullptr;
    size_t size_ = 0;
public:
    SimMoveableBuffer(size_t size):size_(size){ptr_ = SimMalloc(size);}
    ~SimMoveableBuffer(){if(ptr_) SimFree(ptr_);}
    //移动构造函数:转移所有权，O(1)
    SimMoveableBuffer(SimMoveableBuffer &&other) noexcept:ptr_(other.ptr_),size_(other.size_)
    {
        other.ptr_ = nullptr;
        other.size_ = 0;
        std::cout <<"[SimGPU]显存移动构造函数 (零拷贝)\n";
    }
    //移动赋值
    SimMoveableBuffer& operator=(SimMoveableBuffer&& other) noexcept 
    {
        if(this != &other)
        {
            if(ptr_) SimFree(ptr_);
            ptr_ = other.ptr_;
            size_ = other.size_;
            other.size_ = 0;
            other.ptr_ = nullptr;
        }
        return *this;
    }
};
void testMoveSemantics()
{
    std::cout << "====P1 ===移动语义示例\n";
    std::vector<SimMoveableBuffer> buffers;
    SimMoveableBuffer buf1(512);
    //使用std::move 触发移动构造,而非拷贝
    buffers.pushback(std::move(buf1));

    //此时buf1已经为空,可以安全放入新数据而不触发深拷贝；
    buffers.emplace_back(1024);
    std::cout <<"\n";
}
/*
P1 高：多线程与同步
图表学习目标：熟练使用std::mutex,std::atomic,条件变量,并理解内存序;
GPU模拟场景：CPU主线程作为生产者提交模拟Kernel任务，后台工作线程作为消费者
执行任务(模拟GPU异步执行)
*/
class SimGpuRuntime{
    std::queue<std::function<void()>> taskQueue_;
    std::mutex mtx_;
    std::condition_variable cv;
    bool  stop_ = false;
    std::thread worker_;
    std::atomic<int> completeTasks_(0);//原子变量统计完成任务数；
public:
    SimGpuRuntime(){
        worker_ = std::thread([this](){
            while(true)
            {
                std::function<void()> task;
                {
                    std::unique_lock<std::mutex> lock(mtx_);
                    cv_.wait(lock,[this](){return stop_ || !taskQueue_.empty();})
                    if(stop_ && taskQueue_.empty()) return;
                    task = std::move(taskQueue_.front());
                    taskQueue_.pop();
                }   
                task();//执行模拟kernel
                completedTasks_.fetch_add(1,std::memory_order_relaxed); 
            }
        });        
    }
    ~SimGpuRuntime()
    {
        {
            std::lock_guard<std::mutex> lock(mtx_);
            stop_ = true;
        }
        cv_.notify_all();
        if(worker_.joinable()) worker_.join();
    }
    void submit(std::function<void()> task)
    {
        {
            std::lock_guard<std::mutex> lock(mtx_);
        }
        cv_.notify_one();
    }
    int getCompleteTasks() const {return completedTasks_.load();}
};
void testMultithreading()
{
    std::cout <<"====== P1 多线程与同步示例\n";
    SimGpuRuntime runtime;
    //提交 5个模拟kernel任务
    for(int i = 0; i < 5;i++)
    {
        runtime.submit([i](){
            std::cout<<"[SimGpu]执行 Kernel 任务"<< i <<"线程"<<std::this_thread::get_id()<<")\n";
        });
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(100));//等待执行完成；
    std::cout<<"已完成任务数："<< runtime.getCompletedTasks()<<"\n\n";
}
/*
图表学习目标：知道vector，map,unorder_map的底层结构和复杂度，能按照场景选择；
GPU模拟场景：
unordered_map:O(1) 查找已注册的模拟Kernel(如字符串名字到函数指针的映射)；
vector:存储连续的模拟Stream列表；
map:维护优先级排序的模拟任务调度队列；
*/
void testSTLContainer()
{
    std::cout <<"======P2 STL 容器示例===\n";
    //1.unordered_map:O(1)查找,用于kernel注册表
    std::unordered_map<std::string,std::function<void()>> kernelRegistry;
    kernelRegistry["VecAdd"] = [](){std::cout<<"执行,VecAdd\n";}
    kernelRegistry["MatMul"] = [](){std::cout<<"执行,MatMul\n"}
    auto it = kernelRegistry.find("VecAdd");
    if(it != kernelRegistry.end())
    {
        it->second();
    }
    //2.vector:连续存储,用于管理GPU设备或者Stream列表
    std::vector<std::shared_ptr<SimStream>> streamList;
    streamList.push_back(std::make_shared<SimStream>(1));
    streamList.push_back(std::make_shared<SimStream>(2));
    //3.map:有序，用于优先级调度
    std::map<int,std::vector<std::string>> priorityQueue;
    priorityQueue[1].push_back("HighPriorityKernel");
    priotityQueue[5].push_back("LowPriorityKernel");
    std::cout<<"最高优先级任务："<<priorityQueue.begin()->second[0] <<"\n\n";    

}
/*P2中:模板基础
图表学习目标：能看懂模板代码，会写简单的函数模板和类模板
GPU模拟场景,编写通用的显存分配与数据拷贝模板，支持任意数据类型,避免为float,int重复写逻辑;
*/

//[模板类：通用模拟显存池]
template <typename T>
class SimGenericBuffer{
    T* data_ = nullptr;
    size_t size_ = 0;
public:
    explicit SimGenericBuffer(size_t count):size_t(count)
    {
        data_ = static_cast<T*>(Simalloc(count *sizeof(T)));
    }
    ~SimGenericBuffer()
    {
        if(data_) SimFree(data_);
    }
    //模拟数据上传（Host--->Device）
    void upload(Const T* hostData,size_t count)
    {
        std::memcpy(data_,hostData,count * sizeof(T));
        std::cout<< "[SimGPU] 上传" << count <<"个" << typeoid(T).name()<<"数据\n";
   }
   T* data() { return data_;}
};
// [模板函数:通用的模拟Kernel，启动]
template <typename Func,typename... Args>
void launchSimKernel(Func && func,Args &&...args)
{
    std::cout<<"[SimGPU] 模拟 Kernel 启动...\n";
    std::forward<func>(func)(std::forward<Args>...);    
}
void testTemplates()
{
    std::cout <<"====P2 模板基础示例====\n";
    SimGenericBuffer<float> floatBuffer(1024);
    float  hostFloatData[1024] = {0};
    floatBuffer.upload(hostFloatData,1024);
    SimGenericBuffer<int> intBuffer(512);
    int hostIntData[512] = {0};
    iniBuffer.upload(hostIntData,512);

    //使用模板函数启动
    launchSimKernel([](int x){std::cout<<"Kernel 接收参数："<<x<<"\n";},42);
    std::cout<<"\n";
}
/*
P3了解:虚函数/多态
图表学习目标,理解虚函数表机制即可,Runtime核心路径通常避免虚函数开销;
GPU模拟场景:设计可扩展的硬件后端接口(如CudaBackend，OpenBackend);
关键权衡:在初始化/配置等非热路径使用虚函数获得扩展性,在核心热路径(如百万次Kernel Launch)
避免虚函数开销；
*/
//抽象后端接口
class  SimBackend{
    public:
        virtual ~SimBackend() = default;
        virtual void allocate(size_t size) = 0;
        virtual void launchKernel(const std::string &name) = 0;
        virtual const char* getName() const = 0;
};
class SimCudaBackend:public SimBackend{
    public:
        void allocate(size_t size) override {SimMalloc(size);}
        void launchKernel(const std::string& name) override{
            std::cout<<"[SimCUDA]启动 kernel:"<<name<<"\n";
        }
        const char* getName() const override {return "SimCUDA";}
};
class SimOpenCLBackend:public SimBackend {
    public:
        void allocate(size_t size) override {SimMalloc(size);}
        void launchKernel(const std::string& name) override{
            std::cout<<"[SimOpenCL] 启动Kernel "<<name <<"\n";
        } 
        const char* getName() const override {return "SimOpenCL";}
}

void testPolymorphism()
{
    std::cout<<"======P3 虚函数/多态示例=====\n";
    //在初始化阶段通过工厂模式选择后端(非热路径,虚函数开销可接受)
    std::unique_ptr<SimBackend> backend;
    bool useCuda = true;
    if(useCuda) 
    {
        backend = std::make_unique<SimCudaBackend>();    
    }
    else{
        backend = std::make_unique<SimOpenCLBackend>();
    }
    backend->allocate(1024);
    backend->launchKernel("MatMul");
    //提示：如果在每秒数百万次调用的热路径中,应使用模板(如CRTP)替代 虚函数以实现内敛；
    std::cout<<"\n";
}
int main(){
    std::cout<< "=========模拟GPU Runtime C++ 核心技能演示\n";
    testRAII();
    testSmartPointers();
    testMoveSemantics();
    testMultithreading();
    testSTLContainer();
    testPolymorphism();
    std::cout<<"=================演示结束=========\n";
    return 0;
}