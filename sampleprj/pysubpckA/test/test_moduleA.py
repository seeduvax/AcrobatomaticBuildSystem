import unittest
import sampleprj.pysubpckA.moduleA as moduleA

class test_moduleA(unittest.TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_toto(self):
        t=moduleA.Toto()
        self.assertFalse(t.check())

    def test_static(self):
        self.assertTrue(moduleA.staticToto.check())

    def test_addMember(self):
        moduleA.addMember('key',42)
        self.assertTrue(hasattr(moduleA.staticToto,'key'))
        self.assertEqual(42,moduleA.staticToto.key)

if __name__ == '__main__':
    unittest.main()
