#ifndef __ABS_PROFILER_H__
#define __ABS_PROFILER_H__

#ifdef TRACY_ENABLE
#ifdef __cplusplus
#include "Tracy.hpp"
#include "TracyC.h"
#include <string.h>
#include <stack>

#define GRAY 0x404040
#define RED 0x800000
#define GREEN 0x008000
#define BLUE 0x000080
#define LIGHT(x) 0x707070 | x
#define DARK(x) x / 2
namespace AcrobatomaticBuildSystem {
class TracyRegionContext {
public:
    static inline void push(TracyCZoneCtx ctx) {
        _instance._ctx.push(ctx);
    }
    static inline TracyCZoneCtx pop() {
        TracyCZoneCtx ctx=_instance._ctx.top();
        _instance._ctx.pop();
        return ctx;
    }
private:
    std::stack<TracyCZoneCtx> _ctx;
    static TracyRegionContext _instance;
};
}
#define PROFILER_FUNCTION ZoneScoped; ZoneColor(0);
#define PROFILER_FUNCTION_COL(color) ZoneScoped; ZoneColor(tracy::Color:: color);
#define PROFILER_REGION(name) ZoneScoped; ZoneName(name,strnlen(name,256));
#define PROFILER_REGION_COL(name,color) ZoneScoped; ZoneName(name,strnlen(name,256)); ZoneColor(tracy::Color:: color);
#define PROFILER_REGION_BEGIN(name) {\
    TracyCZoneN(TracyRegionContext_ctx,name,true);\
    AcrobatomaticBuildSystem::TracyRegionContext::push(TracyRegionContext_ctx);\
}
#define PROFILER_REGION_END TracyCZoneEnd(AcrobatomaticBuildSystem::TracyRegionContext::pop())
#define PROFILER_THREAD(name) tracy::SetThreadName(name);
#define PROFILER_FRAME(name) FrameMarkNamed(name);
#define PROFILER_PLOT(name,value) TracyPlot(name,value);
#define PROFILER_SETUP AcrobatomaticBuildSystem::TracyRegionContext AcrobatomaticBuildSystem::TracyRegionContext::_instance; \
extern "C" {\
    TracyCZoneCtx _abs_tracy_profiler_pop_context() {\
        return AcrobatomaticBuildSystem::TracyRegionContext::pop();\
    }\
    void _abs_tracy_profiler_push_context(TracyCZoneCtx ctx) {\
        AcrobatomaticBuildSystem::TracyRegionContext::push(ctx);\
    }\
}
#else /* __cplusplus */
#include "TracyC.h"
TracyCZoneCtx _abs_tracy_profiler_pop_context();
void _abs_tracy_profiler_push_context(TracyCZoneCtx ctx);
#define PROFILER_REGION_BEGIN(name) TracyCZoneN(TracyRegionContext_ctx,name,1);_abs_tracy_profiler_push_context(TracyRegionContext_ctx);
#define PROFILER_REGION_END TracyCZoneEnd(_abs_tracy_profiler_pop_context());
#define PROFILER_THREAD(name) TracyCSetThreadName(name);

#define PROFILER_FUNCTION
#endif /* __cplusplus */
// Start stop not really supported by tracy, ignoring
#define PROFILER_START
#define PROFILER_STOP
#endif /* TRACY_ENABLE */

#ifdef BUILD_WITH_EASY_PROFILER
#ifdef __cplusplus
#include "easy/profiler.h"
#include "easy/arbitrary_value.h"
#include <cstdlib>
#define PROFILER_FUNCTION EASY_FUNCTION(profiler::colors:: PROFILER_COLOR);
#define PROFILER_FUNCTION_COL(color) EASY_FUNCTION(profiler::colors:: color);
#define PROFILER_REGION(name) EASY_BLOCK(name, profiler::colors:: PROFILER_COLOR);
#define PROFILER_REGION_COL(name,color) EASY_BLOCK(name, profiler::colors:: color);
#define PROFILER_REGION_BEGIN(name) EASY_NONSCOPED_BLOCK(name, profiler::colors:: PROFILER_COLOR);
#define PROFILER_REGION_END EASY_END_BLOCK;
#define PROFILER_THREAD(name) EASY_THREAD(name);
#define PROFILER_FRAME(name) EASY_NONSCOPED_BLOCK(name,profiler::colors::White); EASY_END_BLOCK;
#define PROFILER_PLOT(name, value) EASY_VALUE(name, value);

#include <iostream>
#define PROFILER_START \
       if (!profiler::isEnabled()) {\
           if (std::getenv("PROFILER_EVENT_TRACING")!=nullptr) {\
               EASY_SET_EVENT_TRACING_ENABLED(true);\
               EASY_SET_LOW_PRIORITY_EVENT_TRACING(false);\
               std::cout << "==P== ENABLE EVENT TRACING : cs_profiling_info.log" << std::endl;\
           }\
           if (std::getenv("PROFILER_NETWORK")==nullptr) {\
               std::cout << "==P== ENABLE PROFILER" << std::endl;\
               EASY_PROFILER_ENABLE;\
           } else {\
               std::cout << "==P== ENABLE PROFILER NETWORK" << std::endl;\
               profiler::startListen();\
           }\
      } else {\
           std::cout << "==P== PROFILER IS ALREADY ENABLED" << std::endl;\
      }
#define PROFILER_STOP \
       if (profiler::isEnabled()) {\
          EASY_SET_EVENT_TRACING_ENABLED(false);\
           std::cout << "==P== STOPPING PROFILER" << std::endl;\
           EASY_PROFILER_DISABLE;\
           const char* profFile = std::getenv("PROFILER_FILE");\
           if (profFile==nullptr) profFile = "profiler.prof";\
           profiler::dumpBlocksToFile(profFile);\
           std::cout << "==P== PROFILER FILE GENERATED : " << profFile << std::endl;\
      }
#define PROFILER_SETUP \
namespace AcrobatomaticBuildSystem {\
class EasyProfilerActivator {\
public:\
    EasyProfilerActivator() {\
    }\
    ~EasyProfilerActivator() {\
        PROFILER_STOP \
    }\
    static EasyProfilerActivator _instance;\
};\
EasyProfilerActivator EasyProfilerActivator::_instance;\
} \
extern "C" { \
    void _abs_easy_profiler_start() {\
        PROFILER_START \
    } \
    void _abs_easy_profiler_stop() {\
        PROFILER_STOP \
    } \
    void _abs_easy_profiler_region_begin(const char* name) {\
        PROFILER_REGION_BEGIN(name) \
    } \
    void _abs_easy_profiler_region_end() {\
        PROFILER_REGION_END \
    } \
    void _abs_easy_profiler_thread(const char* name) {\
        PROFILER_THREAD(name) \
    } \
}
#else /* __cplusplus */
void _abs_easy_profiler_start();
void _abs_easy_profiler_stop();
#define PROFILER_START _abs_easy_profiler_start();
#define PROFILER_STOP _abs_easy_profiler_stop();
#define PROFILER_REGION_BEGIN(name) _abs_easy_profiler_region_begin(name);
#define PROFILER_REGION_END _abs_easy_profiler_region_end();
#define PROFILER_THREAD(name) _abs_easy_profiler_thread(name);
#endif /* __cplusplus */
#endif /* BUILD_WITH_EASY_PROFILER */

/* 
 * When no definition applied, set default empty to
 * let everything compile well when the profiler is
 * not activated.
 */
#if !defined(TRACY_ENABLE) && !defined(BUILD_WITH_EASY_PROFILER)
#define PROFILER_FUNCTION
#define PROFILER_FUNCTION_COL(...)
#define PROFILER_REGION(...)
#define PROFILER_REGION_COL(...)
#define PROFILER_REGION_BEGIN(...)
#define PROFILER_REGION_END
#define PROFILER_THREAD(...)
#define PROFILER_FRAME(...)
#define PROFILER_PLOT(...)
#define PROFILER_SETUP
#define PROFILER_START
#define PROFILER_STOP
#endif /* any profiler defined */


#endif /* __ABS_PROFILER_H__ */
