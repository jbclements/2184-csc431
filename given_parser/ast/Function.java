package ast;

import java.util.List;

public class Function
{
   private final int lineNum;
   private final String name;
   private final Type retType;
   private final List<Declaration> params;
   private final List<Function> functions;
   private final List<Declaration> locals;
   private final Statement body;

   public Function(int lineNum, String name, List<Declaration> params,
                   Type retType, List<Function> functions, List<Declaration> locals,
                   Statement body)
   {
      this.lineNum = lineNum;
      this.name = name;
      this.params = params;
      this.retType = retType;
      this.functions = functions;
      this.locals = locals;
      this.body = body;
   }
}
