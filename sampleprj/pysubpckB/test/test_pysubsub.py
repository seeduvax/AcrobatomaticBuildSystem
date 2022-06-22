# -*-coding:Utf-8 -*
import unittest
from sampleprj.pysubpckB.pysubsub.subsub import subVar

class test_pysubsub(unittest.TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_subVar(self):
        self.assertEqual(666,subVar)

if __name__ == '__main__':
    unittest.main()
