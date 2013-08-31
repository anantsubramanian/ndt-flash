package {
  import flash.display.Sprite;
  /**
   * Class that tests methods of the class NDTUtils.
   * Methods that are tested : prtdbl trim
   */
   public class TestNDTUtils extends Sprite{
     public function TestNDTUtils() {
       trace("Testing method prtdbl:");
       if (testprtdbl())
         trace("Method prtdbl passed tests");
       else
         trace("Method prtdbl : test failed !");
       trace("Testing method trim: ");
       if (testtrim())
         trace("Method trim passed tests");
       else
         trace("Method prtdbl : test failed !");
     }
     
     private function testprtdbl():Boolean {
       if (NDTUtils.prtdbl(2365.43341) != "2365.43")
         return false;
       if (NDTUtils.prtdbl(10.003) != "10.00")
         return false;
       if (NDTUtils.prtdbl(6543.1) != "6543.1")
         return false;
       if (NDTUtils.prtdbl(0) != "0")
         return false;
       if (NDTUtils.prtdbl(12.0) != "12")
         return false;
      return true;
     }
     
     private function testtrim():Boolean {
       if (NDTUtils.trim("   Anant") != "Anant")
         return false;
       if (NDTUtils.trim("A    ") != "A")
         return false;
       if (NDTUtils.trim("   Anant    ") != "Anant")
         return false;
       if (NDTUtils.trim("") != "")
         return false;
       if (NDTUtils.trim(" A n a n t  ") != "A n a n t")
         return false;
       if (NDTUtils.trim("     a       b   ") != "a       b")
         return false;
      return true;
     }
   }
}
