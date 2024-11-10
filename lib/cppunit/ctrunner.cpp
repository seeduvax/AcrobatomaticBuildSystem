/* 
 * ctrunner : CPPUnit console text runner.
 * - outputs text progression as log message on clog stream (defaultly stderr)
 * - optionnaly output xml file using JUnit ant task XML format.  
 *
 * Tabs = 4 chars
 * copyright (C) 2016 Sebastien Devaux
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 *
 *              Sebastien Devaux <sebastien.devaux@laposte.net>
 */


#include "cppunit/TestResult.h"
#include "cppunit/plugin/PlugInManager.h"
#include "cppunit/TestRunner.h"
#include "cppunit/TestListener.h"
#include "cppunit/Test.h"
#include "cppunit/TestCase.h"
#include "cppunit/Exception.h"
#include "cppunit/extensions/TestFactoryRegistry.h"
#include "cppunit/tools/XmlDocument.h"
#include "cppunit/tools/XmlElement.h"
#include <sys/types.h>
#include <regex.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <vector>

using namespace CPPUNIT_NS;
using namespace std;

class TestController: public TestResult {
private:
	struct timespec _startTime;
	double _duration;
	bool _enabled;
	bool _error;
	vector<string> _filters;
	CPPUNIT_NS::Exception* _ex;
	void checkEnabled(Test* test) {
		_enabled=dynamic_cast<TestCase*>(test)==NULL || _filters.size()==0;
		int i=0;
		while (!_enabled && i<_filters.size()) {
			string filter=_filters[i];
			bool pM=filter[0]=='+';
			regex_t reg;
			regcomp(&reg,&(filter.c_str()[1]),0);
			regmatch_t pmatch[1];
			int match=regexec(&reg,test->getName().c_str(),1,pmatch,0);
			_enabled=pM?match==0:match!=0;
			regfree(&reg);
			i++;
		}
        _enabled=_enabled && (test->getName().find("__disabled_")==string::npos);
	}	
	
public:
	TestController() {
		_enabled=true;
		_error=false;
		_duration=0;
		_ex=NULL;
	}
	virtual ~TestController() {
		if (_ex!=NULL) {
			delete _ex;
			_ex=NULL;
		}
	}	
	virtual void addFailure(Test* test, Exception* e) {
		_ex=e;
		_error=false;
	}
	virtual void addError(Test* test, Exception* e) {
		_ex=e;
		_error=true;
	}
	Exception* getException() {
		return _ex;
	}
	bool isError() {
		return _error;
	}
	virtual void startTest(Test* test) {
		_duration=0;
		_error=false;
		if (_ex!=NULL) {
			delete _ex;
			_ex=NULL;
		}
		checkEnabled(test);	
		TestResult::startTest(test);
		clock_gettime(CLOCK_REALTIME,&_startTime);
	}
	virtual void endTest(Test* test) {
		struct timespec endTime;
		clock_gettime(CLOCK_REALTIME,&endTime);
		_duration=(endTime.tv_sec-_startTime.tv_sec)+
			(endTime.tv_nsec-_startTime.tv_nsec)/1000000000.0;
		TestResult::endTest(test);
	}
	virtual bool protect(const Functor &functor,
				Test *test,
				const string &shortDescription) {
		if (_enabled) {
			return TestResult::protect(functor,test,shortDescription);
		}
		return false;
	}
	bool isEnabled() {
		return _enabled;
	}
	double getDuration() {
		return _duration;
	}
	void addFilter(char * filter,bool match) {
		string f=match?"+":"-";
		f+=filter;
		_filters.push_back(f);
	}
};

#define LOGINFO(msg) { \
	struct timespec timestamp; \
	clock_gettime(CLOCK_REALTIME,&timestamp); \
	clog << timestamp.tv_sec << "." \
		<< setfill('0') << setw(9) << timestamp.tv_nsec \
		<< "\t"<<pthread_self()<<"[cppunit]\tINFO\t" <<msg<<endl; \
}

class TestLogger: public TestListener {
private:
	TestController* _controller;
public:
	void startTest(Test* test) {
		if (_controller!=NULL && !_controller->isEnabled()) {
			LOGINFO("Skipping disabled test: "<<test->getName());
		}
		else {
			LOGINFO("Starting test: "<<test->getName());
		}
	}
	void endTest(Test* test) {
		if (_controller!=NULL && !_controller->isEnabled()) {
			// disabled test, nothing to log.
		}
		else if (_controller!=NULL) {
			Exception* ex=_controller->getException();
			if (ex!=NULL) {
				LOGINFO("Test failed: "<<test->getName()
					<<"@"<<ex->sourceLine().fileName()<<":"
					<<ex->sourceLine().lineNumber()
					<<", duration="
					<<(_controller->getDuration()*1000)
					<<" ms, error="
					<<ex->what());
			}
			else {
				LOGINFO("Test completed: "<<test->getName()
					<<", duration="
					<<(_controller->getDuration()*1000)<<" ms.");
			}
		}
		else {
			LOGINFO("Test completed: "<<test->getName());
		}
	}
	void startSuite(Test* suite) {
		LOGINFO("Starting test suite: "<<suite->getName());
	}
	void endSuite(Test* suite) {
		LOGINFO("Test suite completed: "<<suite->getName());
	}
	void startTestRun(Test* test, TestResult * evManager) {
		_controller=dynamic_cast<TestController*>(evManager);
		LOGINFO("Starting: "<<test->getName());
	}
	void endTestRun(Test* test, TestResult * evManager) {
		LOGINFO("Completed: "<<test->getName());
	}
};

class TestXmlReporter: public TestListener {
private:
	TestController* _controller;
	XmlDocument _xml;
	class Node {
	public:
		double time;
		int disabled;
		int failures;
		int tests;
		int errors;
		XmlElement* node;
		Node * parent;
	};
	struct Node * _cNode;
	string _path;
	char _hostname[64];
	void addTimeAttribute(XmlElement* e,double time,bool f33) {
		ostringstream s;
        if (f33) {
            s << std::fixed << std::setprecision(3);
        }
		s << time;
		e->addAttribute("time",s.str().c_str());
	}
	void pushNode(const char * elemName) {
		struct Node * node=new Node();
		node->time=0;
		node->disabled=0;
		node->failures=0;
		node->tests=0;
		node->errors=0;
		node->node=NULL;
		node->parent=_cNode;
		node->node=new XmlElement(elemName);
		if (_cNode!=NULL) {
			_cNode->node->addElement(node->node);
		}
		_cNode=node;
	}
	void popNode(bool leaf=false) {
		Node * parent=_cNode->parent;
		if (parent!=NULL) {
			parent->tests+=_cNode->tests;
			parent->time+=_cNode->time;
			parent->disabled+=_cNode->disabled;
			parent->failures+=_cNode->failures;
			parent->errors+=_cNode->errors;
		}
		if (!leaf) {
			_cNode->node->addAttribute("tests",_cNode->tests);
            if (_cNode->parent!=NULL) {
    			_cNode->node->addAttribute("skipped",_cNode->disabled);
            }
			_cNode->node->addAttribute("failures",_cNode->failures);
			_cNode->node->addAttribute("errors",_cNode->errors);
		}
    	addTimeAttribute(_cNode->node,_cNode->time,!leaf);
		delete _cNode;
		_cNode=parent;
	}

public:
	TestXmlReporter(string path): _xml("utf-8") {
		_cNode=NULL;
		_path=path;
		gethostname(_hostname,sizeof(_hostname));
	}
	virtual ~TestXmlReporter() {
	}
	void startTest(Test* test) {
		pushNode("testcase");
		_cNode->node->addAttribute("name",test->getName());
	}
	void endTest(Test* test) {
		_cNode->tests=1;
		if (_controller!=NULL && !_controller->isEnabled()) {
			_cNode->node->addAttribute("status","skipped");
			_cNode->disabled=1;
            XmlElement* skipNode=new XmlElement("skipped");
            skipNode->addAttribute("message",
                "Test execution filtered by ctrunner argument");
            _cNode->node->addElement(skipNode);
		}
		else if (_controller!=NULL) {
			_cNode->time=_controller->getDuration();
			Exception* ex=_controller->getException();
			if (ex!=NULL) {
				if (_controller->isError()) {
					_cNode->errors=1;
				}
				else {
					_cNode->failures=1;
				}
/*
				_cNode->node->addAttribute("status",
					_controller->isError()?"error":"failure");
*/
				XmlElement* failureNode=new XmlElement(
					_controller->isError()?"error":"failure");
				_cNode->node->addElement(failureNode);
				failureNode->setContent(ex->what());
				if (!_controller->isError()) {
					ostringstream s;
					s << ex->sourceLine().fileName() <<":"
						<<ex->sourceLine().lineNumber();
					failureNode->addAttribute("message",s.str().c_str());
					failureNode->addAttribute("type","Assertion failed");
				}
			}
			else {
//				_cNode->node->addAttribute("status","pass");
			}
		}
		popNode(true);
	}
	void startSuite(Test* suite) {
		pushNode("testsuite");
		_cNode->node->addAttribute("name",suite->getName());
		ostringstream s;
		struct timespec timestamp;
		clock_gettime(CLOCK_REALTIME,&timestamp);
		s << timestamp.tv_sec << "." << setfill('0') << setw(9) 
			<< timestamp.tv_nsec;
		_cNode->node->addAttribute("timestamp",s.str().c_str());
	}
	void endSuite(Test* suite) {
		_cNode->node->addAttribute("hostname",_hostname);
		popNode();
	}
	void startTestRun(Test* test, TestResult * evManager) {
		_controller=dynamic_cast<TestController*>(evManager);
		pushNode("testsuites");
		_xml.setRootElement(_cNode->node);
	}
	void endTestRun(Test* test, TestResult * evManager) {
		popNode();
	}
	void write() {
		ofstream f(_path.c_str());
		f << _xml.toString();
		f.close();
	}
};

int main(int argc, char ** argv) {
    TestController controller;
	TestRunner runner;
	PlugInManager plugInManager;
	TestLogger logger;
	controller.addListener(&logger);
	TestXmlReporter* xmlReporter=NULL;
	int mode=0;
	for (int i=1;i<argc;i++) {
		switch(mode) {
			case 1:
				xmlReporter=new TestXmlReporter(argv[i]);
				controller.addListener(xmlReporter);
				mode=0;
				break;
			case 2:
				controller.addFilter(argv[i],true);
				mode=0;
				break;
			case 3:
				controller.addFilter(argv[i],false);
				mode=0;
				break;
			default: {
				if (strcmp(argv[i],"-x")==0) {
					mode=1;
				}
				else if (strcmp(argv[i],"+f")==0) {
					mode=2;
				}
				else if (strcmp(argv[i],"-f")==0) {
					mode=3;
				}
				else {
					plugInManager.load(argv[i]);
					plugInManager.addListener(&controller);
					runner.addTest(TestFactoryRegistry::getRegistry().makeTest());
				}
			}	break;
		}
	}

	try {
		runner.run(controller);
    }
    catch ( ... ) {
		cerr << "Unexpected error while running  cppunit tests..." << endl; 
		return 1;
    }

	if (xmlReporter!=NULL) {
		xmlReporter->write();
		controller.removeListener(xmlReporter);
		delete xmlReporter;
	}

	return 0;
}
