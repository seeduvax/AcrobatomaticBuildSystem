package test;
import org.junit.*;
import static org.junit.Assert.*;
import static org.junit.Assume.*;
import static org.hamcrest.CoreMatchers.*;
import fr.example.BuildScriptTester.jmod.Main;

/**
 *
 */
public class TestMain {
    /**
     * Pre-test initialisations.
     */
     //Conditional Class loading : 
     //if the command is make test TOPTS=-Dskipclass, all test are skipped and the xml report contains no test case
    @BeforeClass   static public void ignoreSKIPCLASS(){
       assumeThat(System.getProperty("skipclass"),nullValue());
    }

  @Before public void setUp() {
       System.out.println(">> Setup");
    }

  
   //Conditional test execution => By default tests will pass
   //if the command is make test TOPTS=-Dnotest, all test are skipped, but considered as passed by the runner
   //(wether it is JUnitCore or the AntXml  runner)
   @Before public void ignoreIfNOTEST(){
            System.out.println("notest = \"" +  System.getProperty("notest") + "\"");
            assumeThat(System.getProperty("notest"),nullValue());
    }
    /**
     * Post-test finalizations.
     */
    @After public void tearDown() {
        System.out.println(">> TearDown");
    }

    /**
     *
     */
    @Test public void testPlop() {
        System.out.println(">> starting testPlop.");
        assertEquals(true,Main.getTrue());
        // force failure to check test framework.
        // uncommented when such test is needed.
        // assertEquals(false,Main.getTrue());
        System.out.println(">> testPlop completed.");
    }
   @Test public void testPlip() {
        assumeThat(System.getProperty("ignore"),nullValue());
        System.out.println(">> starting testPlup.");
        assertEquals(true,Main.getTrue());
        // force failure to check test framework.
        // uncommented when such test is needed.
        // assertEquals(false,Main.getTrue());
        System.out.println(">> testPlip completed.");
   }
   @Test public void testKO() {
        System.out.println(">> starting testPlip.");
        assertEquals(true,Main.getTrue());
        // force failure to check test framework.
        // uncommented when such test is needed.
         assertEquals(false,Main.getTrue());
        System.out.println(">> testPlip completed.");
   }



}
