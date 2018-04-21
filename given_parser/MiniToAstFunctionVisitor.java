import org.antlr.v4.runtime.tree.TerminalNode;

import java.util.List;
import java.util.ArrayList;

import ast.*;

public class MiniToAstFunctionVisitor
   extends MiniBaseVisitor<Function>
{
   private final MiniToAstTypeVisitor typeVisitor = new MiniToAstTypeVisitor();
   private final MiniToAstDeclarationsVisitor declarationsVisitor =
      new MiniToAstDeclarationsVisitor();
   private final MiniToAstStatementVisitor statementVisitor =
      new MiniToAstStatementVisitor();

   @Override
   public Function visitFunction(MiniParser.FunctionContext ctx)
   {
      return new Function(
         ctx.getStart().getLine(),
         ctx.ID().getText(),
         gatherParameters(ctx.parameters()),
         typeVisitor.visit(ctx.returnType()),
         gatherFunctions(ctx.functions()),
         declarationsVisitor.visit(ctx.declarations()),
         statementVisitor.visit(ctx.statementList()));
   }

   private List<Declaration> gatherParameters(
      MiniParser.ParametersContext ctx)
   {
      List<Declaration> params = new ArrayList<>();

      for (MiniParser.DeclContext dctx : ctx.decl())
      {
         params.add(new Declaration(dctx.getStart().getLine(),
            typeVisitor.visit(dctx.type()), dctx.ID().getText()));
      }

      return params;
   }

  private List<Function> gatherFunctions(MiniParser.FunctionsContext ctx)
   {
      List<Function> funcs = new ArrayList<>();

      for (MiniParser.FunctionContext fctx : ctx.function())
      {
         funcs.add(visit(fctx));
      }

      return funcs;
   }


   @Override
   protected Function defaultResult()
   {
      return new Function(-1, "invalid", new ArrayList<>(),
         new VoidType(), new ArrayList<>(), new ArrayList<>(),
         BlockStatement.emptyBlock());
   }
}
