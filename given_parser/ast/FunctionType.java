package ast;

import java.util.List;

public class FunctionType
   implements Type
{
   private final int lineNum;
   private final List<Type> argTypes;
   private final Type resultType;

   public FunctionType(int lineNum, List<Type> argTypes,
     Type resultType)
   {
      this.lineNum = lineNum;
      this.argTypes = argTypes;
      this.resultType = resultType;
   }
}
