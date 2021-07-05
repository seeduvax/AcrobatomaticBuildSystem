#ifndef __ABS_PROFILER_H__
#define __ABS_PROFILER_H___

#ifdef TRACY_ENABLE
#ifdef __cplusplus
#include "Tracy.hpp"
#include <string.h>
#define PROFILER_FUNCTION ZoneScoped;
#define PROFILER_REGION(name) ZoneScoped; ZoneName(name,strnlen(name,256));
#define PROFILER_REGION_BEGIN(name)
#define PROFILER_REGION_END
#define PROFILER_THREAD(name)
#define PROFILER_FRAME(name) FrameMarkNamed(name);
#define PROFILER_PLOT(name,value) TracyPlot(name,value);
#define PROFILER_SETUP
#endif
#endif

#ifdef BUILD_WITH_EASY_PROFILER
#ifdef __cplusplus
#include "easy/profiler.h"
#include "easy/arbitrary_value.h"
#include <cstdlib>
#define PROFILER_FUNCTION EASY_FUNCTION(profiler::colors:: PROFILER_COLOR);
#define PROFILER_REGION(name) EASY_BLOCK(name, profiler::colors:: PROFILER_COLOR);
#define PROFILER_REGION_BEGIN(name) EASY_NONSCOPED_BLOCK(name);
#define PROFILER_REGION_END EASY_END_BLOCK;
#define PROFILER_THREAD(name) EASY_THREAD(name);
#define PROFILER_FRAME(name) EASY_NONSCOPED_BLOCK(name);EASY_END_BLOCK;
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
#define PROFILER_REGION(...)
#define PROFILER_REGION_BEGIN(...)
#define PROFILER_REGION_END
#define PROFILER_THREAD(...)
#define PROFILER_FRAME(...)
#define PROFILER_PLOT(...)
#define PROFILER_START
#define PROFILER_STOP
#endif


#endif /* __ABS_PROFILER_H__ */
