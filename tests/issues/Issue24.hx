package issues;

#if macro
import haxe.macro.Context;
using StringTools;
#else
@:build(issues.Issue24.build())
#end
class Issue24 {
  private var x:Int;
  private var y:Int;
  #if macro
  static function build() {
    for (field in Context.getBuildFields())
      if (field.name.startsWith('x'))
        Context.error('I HaTe vAriAblEs wHaT stARt WitH X', Context.currentPos());
    return null;
  }
  #end
}