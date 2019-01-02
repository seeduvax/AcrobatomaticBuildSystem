
import unittest

class test_xmloutput(unittest.TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_pass_longtime(self):
        a=30000000
        while (a>0):
            a=a-1

    def test_error(self):
        msg = "Hello this test should error ... (not fail)"
        #print(msg)
        #self.assertTrue(False)

    def test_fail(self):
        msg = "Hello this test should fail ... (not error)"
        #print(msg)
        #self.fail(msg)

if __name__ == '__main__':
    unittest.main()
