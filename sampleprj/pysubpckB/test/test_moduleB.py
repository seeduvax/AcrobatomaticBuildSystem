
import unittest
import sampleprj.pysubpckB.moduleB as moduleB
import sampleprj.pysubpckA.moduleA as moduleA

class test_moduleB(unittest.TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_tata(self):
        tata=moduleB.Tata()
        self.assertTrue(isinstance(tata,moduleA.Toto))

if __name__ == '__main__':
    unittest.main()
