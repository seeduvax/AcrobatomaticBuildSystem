# -*-coding:Utf-8 -*

def main_exec(**KWARGS):
    import os, unittest, logging
    from .xmlrunner import XMLTestRunner
    logger = logging.getLogger()
    logger.setLevel(1)
    formatter = logging.Formatter('%(asctime)s\t%(threadName)s\t%(levelname)s\t%(module)s[%(filename)s:%(lineno)d]\t%(message)s', '%s')
    stream_handler = logging.StreamHandler()
    stream_handler.setLevel(1)
    stream_handler.setFormatter(formatter)
    logger.addHandler(stream_handler)
    
    class TestLoader:
        def load(self):
            modules_to_test=[]
            test_dir=os.listdir('test')
            unique_test = KWARGS.get('T', None)
            for test in test_dir:
                if test.startswith('test') and test.endswith('.py') and ((not unique_test) or (unique_test in test)):
                    modules_to_test.append(test.replace('.py',''))
            print 'tests found:',modules_to_test
            alltests= unittest.TestSuite()
            for module in map(__import__, modules_to_test):
                # overide current locals with custom parameters (if needed) 
                # Pythonic gum! ;)
                module.testvars= []
                # add test cases to the suite
                alltests.addTest(
                    unittest.findTestCases(module))
            return alltests

        def loadTestsFromTestCase(self,*a,**k):
            return self.load()

        def loadTestsFromModule(self,*a,**k):
            return self.load()

        def loadTestsFromName(self,*a,**k):
            return self.load()
   
    name='%(APPNAME)s_%(MODNAME)s' % KWARGS
    testRunner=XMLTestRunner(output=KWARGS['TTARGETDIR'],outsuffix=name+'.xml')
    unittest.main(testRunner=testRunner,
                  testLoader=TestLoader(), 
                  argv=('verbose',))
