#include <iostream>
#include <stdexcept>
#include <memory>
#include <utility>
#include <mutex>
#include <vector>
#include <automic>
#include <thread>
#include <condition_variable>
#include <unorderd_map>
#include <string>
#include <cstdlib>
namespace DemoRall
{
    struct simGpuBuffer{
        void* dev_ptr = nullptr;
        size_t bytes = 0;

    struct simGpuBuffer(size_t sz):byte(sz){
        dev_ptr = malloc(sz);
        if(nullptr == dev_ptr)
        {
            throw std::runtime_error("simGpu malloc failed")
        }
        std::cout<< "[RAII] 分配GPU显存,地址："<< dev_ptr <<std::endl;
    }
    ~simGpuBuffer()
    {
        if(dev_ptr)
        {
            free(dev_ptr);
            std::cout<<"[RAII]释放GPU显存,地址："<< dev_ptr <<"\n";
            dev_ptr = nullptr;
        }
    }
    simGpu(const SimGpuBuffer&) = delete;
    simGpuBuffer& operator=(const SimGpuBuffer&) = delete;
    void *get() const {return dev_ptr;}
    }
    void run()
    {
        std::cout << "\n==== P0 RAII demo====\n";
        try{
            simGpuBuffer buf(1024);
            throw std::runtime_error("some error");

        }catch(const std::exception& e)
        {
            std::cerr<<"catch exception"<<e.what()<<"\n";
        }
    }
}
//P0 最高优先级：智能指针 unique_ptr /shared_ptr /weak_ptr
namespace DemoSmartPtr{
    struct GpuBufferDelete{
        void operator()(void* p) const {
            if(p)
            {
                free(p);
                std::cout<<"[unique_ptr] release gpu buffer,地址："<< p <<"\n";
            }
        }
    }
    using UniqueGpuBuffer = std::unique_ptr<void,GpuBufferdelete>;
    UniqueGpuBuffer alloc_gpu(size_t bytes)
    {
        void* p = malloc(bytes);
        std::cout<<"alloc gpu ,地址"<< p << "\n";
        return UniqueGpuBuffer(p);
    }
    struct GpuResourcePool;
    struct GpuBufferObj{
        std::weak_ptr<GpuResourcePool> pool;
        void* dev_ptr = nullptr;
    };
    struct GpuResourcePool{
        std::shared_ptr<GpuBufferObj> buffer;
    };
    void run()
    {
        std::cout<<"\n========== p0 SmartPtr Demo\n";
        auto buf = alloc_gpu(1024);
        
        //shared_ptr
        void* dev_ptr = malloc(1024);
        auto shared_buf = std::shared_ptr<void>(dev_ptr,[](void*p)
        {
            free(p);
            std::cout<<"[shared_ptr] gpu buffer freed\n";
        });
        auto ref1 = shared_buf;
        auto ref2 = shared_buf;
        std::cout<<"shared_ptr ref count = "<<shared_buf.user_count() <<"\n";

        //weak_pre 解决循环引用的问题
        auto pool = std::make_shared<GpuResourcePool>();
        auto buf_obj = std::make_shred<GpuBufferObj>();
        buf_obj->pool = pool;
        pool->buffer = buf_obj;

    }
}
//P1 最高优先级，移动语义 std::move
namespace DemoMove{
    struct SimGpuBuffer{
        void* ptr = nullptr;
        size_t size = 0;
        explicit  SimGpuBuffer(size_t sz):size(sz)
        {
            ptr = malloc(sz);
            std::cout<<"[ctor] alloc gpu buffer"<< ptr <<"\n";
        }
        ~SimGpuBuffer(){
        if(ptr)
        {
            free(ptr);
            std::cout<<"[dtor] free gpu buffer"<<ptr<<"\n";
        }
    }
    SimGpuBuffer(SimGpuBuffer&& other) noexcept {
        ptr = other.ptr;
        size = other.size;
        other.ptr = nullptr;
        other.size = 0;
        std::cout << "[move ctor] transfer ownership\n" ;
    }
    SimGpuBuffer& operator=(SimGpuBuffer&& other) noexcept {
        if(&other == this) return *this;
        if(ptr) free(ptr);
        ptr = other.ptr;
        size = other.size;
        other.ptr = nullptr;
        other.size = 0;
        std::cout <<"[move assign] transfer ownership\n";
        return *this;
    }
    simGpuBuffer(const SimGpuBuffer&) = delete;
    SimGpuBuffer& operator=(const SimGpuBuffer&) = delete;
    };
    SimGpuBuffer create_gpu_buffer(size_t s)
    {
        return SimGpuBuffer(s);
    }
    void run(){
        std::cout <<"\n=========P1 Move Semantics Demo =========\n";
        SimGpuBuffer b1 = create_gpu_buffer(1024);
        SimGpuBuffer b2 = std::move(b1);
    }    
}
//P1 高优先级：多线程与同步mutex/automic/condition_variable
namespace DemoThreadSync{
    class GpuMemPool{
        private:
        std::mutex mtx;
        std::vector<void*> free_list;
        public:
        void* allocate(size_t bytes)
        {
            std::lock_guard<std::mutex> lock(mtx);
            if(!free_list.empty())
            {
                auto p = free_list.back();
                free_list.pop_back();
                return p;
            }
            return malloc(bytes);
        }
        void release(void*p)
        {
            std::lock_guard<std::mutex> lock(mtx);
            free_list.push_back(p);
        }
    }
    std::atomic<int> gpu_task_count(0);
    void submit_gpu_task()
    {
        gpu_task_count.fetch_add(1,std::memory_order_release);
    }
    std::mutex cv_mtx;
    std::condition_variable cv;
    bool  gpu_job_finished = false;
    void gpu_worker_thread()
    {
        std::lock_guard<std::mutex> lock(cv_mtx);
        gpu_job_finished = true;
        cv.notify_one();
    }
    void run()
    {
        std::cout<<"\n ==========P1 Thread Sync Demo\n";
        GpuMemPool pool;
        void* p = pool.allocate(256);
        pool.release(p);
        std::thread t1(submit_gpu_task);
        std::thread t2(submit_gpu_task);
        t1.join();
        t2.join();
        std::count<<"atomic total tasks"<<gpu_task_count.load(std::memory_order_acquire)<<"\n";
        std::thread worker(gpu_woker_thread);
        std::unique_lock(std::mutex) lock(cv_mtx);
        cv.wait(lock,[](){return gpu_job_finished;});
        std::count<<"GPU任务完成\n";
        worker.join();
    }
}
//P2 中优先级，STL容器，vector/unorder_map
namespace DemoSTL{
    using GpuKernelFunc = void(*)();
    void run()
    {
        std::count <<"\n =========P2 STL container Demo====== \n";
        std::vector<void*> gpu_buffer_list;
        gpu_buffer_list.push_back(malloc(256));
        gpu_buffer_list.push_back(malloc(512));
        std::unorder_map<std::string,GpuKernelFunc> kernel_registy;
        kernel_registy["vec_add"] = [](){std::count<<"run vec_add kernel\n";}
        kernel_registy["relu"] = [](){std::count<<"run relu kernel\n";}
        kernel_registy["vec_add"]();
        kernel_registy["relu"]();
        for(auto p:gpu_buffer_list) free(ptr);
    }
}

namespace DemoTemplate{
    template<typename T>
    struct SimGpuBufferT{
        T* ptr = nullptr;
        size_t num_elem;
        explicit  SimGpuBufferT(size_t n):num_elem(n){
            ptr = reinterpret_cast<T*>(malloc(n*sizeof(T)));
        }
        ~SimpGpuBufferT()
        {
            if(ptr) free(ptr);
        }
        SimGpuBufferT(SimGpuBuffer T&& other) noexcept {
            ptr = other.ptr;
            num_elem = other.num_elem;
            other.ptr = nullptr;
        }
    };
    template<typename T>
    void copy_host_to_gpu(T* dev,const T*host,size_t n)
    {
        for(size_t i = 0;i <n;i++)
        {
            dev[i] = host[i];
        }
    }
    void run()
    {
        std::count <<"\n=========P2 Template Demo\n";
        SimGpuBufferT<float> float_buf(128);
        SimGpuBuffer<int> int_buf(128);
        int host_data[] = {1,2,3};
        copy_host_to_gpu(int_buf.ptr,host_data,3);
        std::count<<"template copy done,int_buf[0]" <<int_buf.ptr[0]<<"\n";
    }
}
//P3 了解：多态/虚函数，硬件后端抽象
namespace DemoVirtual{
    struct GpuBackendBase
    {
        virtual ~GpuBackendBase() = default;
        virtual void* alloc_buffer(size_t bytes) = 0;
        virtual void submit_kernel() = 0;   
    };
    struct CudaSimBackend:GpuBackendBase{
        void* alloc_buffer(size_t bytes) override 
        {
            std::cout<<"Sim CUDA Alloc Buffer\n";
            return malloc(bytes);
        }
        void submit_kernel() override {
            std::cout<<"Sim Launch kernel";
        }
    }
    void run(){
        std::cout << "\n =========P3 Virtual Polymorphism Demo\n";
        GpuBackendBase* backend = new CudaSimBackend();
        void* buf = backend->alloc_buffer(1024);
        backend->submit_kernel();
        free(buf);
        delete backend;
    }     
}
// main 依次执行全部demo
//g++ runtime_cpp_demo.cpp -o runtime_cpp_demo -std=c++17 -g -pthread
//./runtime_cpp_demo
int main()
{
    DemoRall::run();
    DemoSmartPtr::run();
    DemoMove::run();
    DemoThreadSync::run();
    DemoSTL::run();
    DemoTemplate::run();
    DemoVirtual::run();
    std::cout<<"\n=======All demo finished=====\n";
    return 0;
}