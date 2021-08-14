#ifndef __ABS_PROFILER_H__
#define __ABS_PROFILER_H__

#ifdef TRACY_ENABLE
#ifdef __cplusplus
#include "Tracy.hpp"
#include "TracyC.h"
#include <string.h>

#define GRAY 0x404040
#define RED 0x800000
#define GREEN 0x008000
#define BLUE 0x000080
#define LIGHT(x) 0x707070 | x
#define DARK(x) x / 2
class TracyRegionContext {
public:
static TracyCZoneCtx _ctx;
};
#define PROFILER_FUNCTION ZoneScoped; ZoneColor(0);
#define PROFILER_FUNCTION_COL(color) ZoneScoped; ZoneColor(tracy::Color:: color);
#define PROFILER_REGION(name) ZoneScoped; ZoneName(name,strnlen(name,256));
#define PROFILER_REGION_COL(name,color) ZoneScoped; ZoneName(name,strnlen(name,256)); ZoneColor(tracy::Color:: color);
#define PROFILER_REGION_BEGIN(name) TracyCZoneN(TracyRegionContext_ctx,name,true); TracyRegionContext::_ctx=TracyRegionContext_ctx;
#define PROFILER_REGION_END TracyCZoneEnd(TracyRegionContext::_ctx)
#define PROFILER_THREAD(name) tracy::SetThreadName(name);
#define PROFILER_FRAME(name) FrameMarkNamed(name);
#define PROFILER_PLOT(name,value) TracyPlot(name,value);
#define PROFILER_SETUP TracyCZoneCtx TracyRegionContext::_ctx;
#endif
#endif

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
#define PROFILER_SETUP \
namespace AcrobatomaticBuildSystem {\
class EasyProfilerActivator {\
public:\
    EasyProfilerActivator() {\
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
      }\
    }\
    ~EasyProfilerActivator() {\
       if (profiler::isEnabled()) {\
          EASY_SET_EVENT_TRACING_ENABLED(false);\
           std::cout << "==P== STOPPING PROFILER" << std::endl;\
           EASY_PROFILER_DISABLE;\
           const char* profFile = std::getenv("PROFILER_FILE");\
           if (profFile==nullptr) profFile = "profiler.prof";\
           profiler::dumpBlocksToFile(profFile);\
           std::cout << "==P== PROFILER FILE GENERATED : " << profFile << std::endl;\
      } else {\
           std::cout << "==P== PROFILER IS ALREADY STOPPED" << std::endl;\
      }\
    }\
    static EasyProfilerActivator _instance;\
};\
EasyProfilerActivator EasyProfilerActivator::_instance;\
} // namespace abs
#endif
#endif

/* 
 * When no definition applied, set default empty to
 * let everything compile well when the profiler is
 * not activated.
 */
#ifndef PROFILER_FUNCTION
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
#endif


#endif /* __ABS_PROFILER_H__ */
