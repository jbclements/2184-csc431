import java.util.List;
import java.util.ArrayList;
import ast.*;

public class MiniToAstTypeVisitor
   extends MiniBaseVisitor<Type>
{
  @Override
   public Type visitIntType(MiniParser.IntTypeContext ctx)
   {
      return new IntType();
   }

   @Override
   public Type visitBoolType(MiniParser.BoolTypeContext ctx)
   {
      return new BoolType();
   }

   @Override
   public Type visitStructType(MiniParser.StructTypeContext ctx)
   {
      return new StructType(ctx.getStart().getLine(), ctx.ID().getText());
   }

   @Override
   public Type visitFunctionType(MiniParser.FunctionTypeContext ctx)
   { 
     return new FunctionType(ctx.getStart().getLine(),
                             collectTypes(ctx.argTypes()),
                             visit(ctx.type()));
   }

   private List<Type> collectTypes(MiniParser.ArgTypesContext ctx)
   {
     List<Type> types = new ArrayList<>();

     for (MiniParser.TypeContext tctx : ctx.type())
     {
       types.add(visit(tctx));
     }

     return types;
   }

   @Override
   public Type visitReturnTypeReal(MiniParser.ReturnTypeRealContext ctx)
   {
      return visit(ctx.type());
   }

   @Override
   public Type visitReturnTypeVoid(MiniParser.ReturnTypeVoidContext ctx)
   {
      return new VoidType();
   }

   @Override
   protected Type defaultResult()
   {
      return new VoidType();
   }
}
