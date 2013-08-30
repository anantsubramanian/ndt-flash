package {
  import flash.display.Sprite;
  /**
   * Class that tests methods of the class NDTUtils.
   * Methods that are tested : prtdbl trim
   */
   public class TestNDTUtils extends Sprite{
     public function TestNDTUtils() {
       trace("Testing method prtdbl:");
       trace("prtdbl(2365.43341) = " + NDTUtils.prtdbl(2365.43341));
       trace("prtdbl(10.003) = " + NDTUtils.prtdbl(10.003));
       trace("prtdbl(6543.1) = " + NDTUtils.prtdbl(6543.1));
       trace("prtdbl(0) = " + NDTUtils.prtdbl(0));
       trace("prtdbl(12.0) = " + NDTUtils.prtdbl(12.0));
       trace("Finished testing method prtdbl.");
       trace("Testing method trim: ");
       trace('trim("   Anant") = "' + NDTUtils.trim("   Anant") + '"');
       trace('trim("A    ") = "' + NDTUtils.trim("A    ") + '"');
       trace('trim("   Anant    ") = "' + NDTUtils.trim("   Anant    ") + '"');
       trace('trim("") = "' + NDTUtils.trim("") + '"');
       trace('trim(" A n a n t  ") = "' + NDTUtils.trim(" A n a n t  ") + '"');
       trace('trim(" A   na n  t  ") = "' + NDTUtils.trim(" A   na n  t  ") + '"');
       trace('trim("     a       b   ") = "' + NDTUtils.trim("     a       b   ") + '"');
       trace("Finished testing method trim.");
     }
   }
}
