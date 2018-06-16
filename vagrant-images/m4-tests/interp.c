#include <stdio.h>
#include <stdlib.h>

// a simple model of the lambda calculus, with numbers and addition added.
// NB: this code does not behave well when called with terms that have
// free variables; we don't do capture-avoiding substitution, so they
// can become captured. This is no problem for closed terms, because
// we don't evaluate inside lambdas.

struct Expr * interp(struct Expr *l);

// we don't have unions, so we just have to smoosh :(
struct Expr {
  int kind; // 0 = number, 1 = variable, 2 = app, 3 = lambda, 4 = plus, 5 = minus, 6 = if>0
  int num; // represents a number or a variable name
  struct Expr *a1;
  struct Expr *a2;
  struct Expr *a3;
};

/* print an integer */
int printint(int i) {
  printf("%d ",i);
  return 0;
}

/* print an integer followed by a newline */
int printintln(int i) {
  printf("%d\n",i);
  return 0;
}

/* read an integer from stdin */
int readint () {
  // should never be visible...:
  int a = 4432;
  int r;
  r = scanf(" %d",&a);
  if (r != 1) {
    fprintf(stderr,"unexpected character on input.\n");
    exit(1);
  }
  return a;
}

struct Expr *newExpr() {
  struct Expr *e;
  e = malloc(sizeof(struct Expr));
  if (e == NULL) {
    fprintf(stderr,"malloc fail\n");
    exit(1);
  }
  return e;
}
// constructors for each of the language forms:

struct Expr * makenum(int n) {
  struct Expr *e;
  e = newExpr();
  e->kind = 0;
  e->num = n;
  return e;
}

struct Expr * makevar(int name) {
  struct Expr *e;
  e = newExpr();
  e->kind = 1;
  e->num = name;
  return e;
}

struct Expr * makeapp(struct Expr *fn, struct Expr *arg) {
  struct Expr *e;
  e = newExpr();
  e->kind = 2;
  e->a1 = fn;
  e->a2 = arg;
  return e;
}

struct Expr * makelam(int var, struct Expr *body) {
  struct Expr *e;
  e = newExpr();
  e->kind = 3;
  e->num = var;
  e->a1 = body;
  return e;
}

struct Expr * makeplus(struct Expr *l, struct Expr *r) {
  struct Expr *e;
  e = newExpr();
  e->kind = 4;
  e->a1 = l;
  e->a2 = r;
  return e;
}

struct Expr * makeminus(struct Expr *l, struct Expr *r) {
  struct Expr *e;
  e = newExpr();
  e->kind = 5;
  e->a1 = l;
  e->a2 = r;
  return e;
}

struct Expr * makeifgt0(struct Expr *tst, struct Expr *thn, struct Expr *els) {
  struct Expr *e;
  e = newExpr();
  e->kind = 6;
  e->a1 = tst;
  e->a2 = thn;
  e->a3 = els;
  return e;
}


// given replace every instance of vars numbered
// "from" with "to" in "in"
struct Expr * subst(int from, struct Expr *to, struct Expr *in) {
  if (in->kind == 0) {
    return in;
  } else {
    if (in->kind == 1) {
      if (in->num == from) {
        return to;
      } else {
        return in;
      }
    } else {
      if (in->kind == 2) {
        return makeapp(subst(from,to,in->a1),
                       subst(from,to,in->a2));        
      } else {
        if (in->kind == 3) {
          if (in->num == from) {
            return in;
          } else {
            return makelam(in->num,subst(from,to,in->a1));
          }
        } else {
          if (in->kind == 4) {
            return makeplus(subst(from,to,in->a1),
                            subst(from,to,in->a2));
          } else {
            if (in->kind == 5) {
              return makeminus(subst(from,to,in->a1),
                               subst(from,to,in->a2));
            } else {
              return makeifgt0(subst(from,to,in->a1),
                            subst(from,to,in->a2),
                            subst(from,to,in->a3));
            }
          }
        }
      }
    }
  }
}

// given two values, check they're numbers and add them:
struct Expr * add(struct Expr *a, struct Expr *b) {
  int dc;
  if ((a->kind == 0)&&(b->kind == 0)) {
    return makenum(a->num + b->num);
  } else {
    dc = 1 / 0;
    // bogus return value
    return a;
  }
}

// given two values, check they're numbers and subtract them:
struct Expr * subtract(struct Expr *a, struct Expr *b) {
  int dc;
  if ((a->kind == 0)&&(b->kind == 0)) {
    return makenum(a->num - b->num);
  } else {
    dc = 1 / 0;
    // bogus return value
    return a;
  }
}

// given a value and two expressions, check that the first is
// a number; if it is, and it's >= 0, evaluate & return the
// then clause, otherwise evaluate & return the else clause
struct Expr * iftest(struct Expr *tst, struct Expr *thn, struct Expr *els) {
  int dc;
  if (tst->kind == 0) {
    if (tst->num > 0) {
      return interp(thn);
    } else {
      return interp(els);
    }
  } else {
    dc = 1 / 0;
    // bogus return
    return tst;
  }
}

// given two values, check the first is a lam and apply
// it to the second using substitution
struct Expr * app(struct Expr *f, struct Expr *a) {
  int dc;
  if (f->kind == 3) {
    return interp(subst(f->num,a,f->a1));
  } else {
    dc = 1 / 0;
    // bogus return value:
    return f;
  }
}

// parse an expr from input. Each form is indicated
// by its corresponding number, followed by its serialized
// fields
struct Expr * parseExpr() {
  int i, m;
  i = readint();
  if (i == 0) {
    m = readint();
    return makenum(m);
  } else {
    if (i == 1) {
      m = readint();
      return makevar(m);
    } else {
      if (i == 2) {
        return makeapp(parseExpr(),parseExpr());
      } else {
        if (i == 3) {
          m = readint();
          return makelam(m,parseExpr());
        } else {
          if (i == 4) {
            return makeplus(parseExpr(),parseExpr());
          } else {
            if (i == 5) {
              return makeminus(parseExpr(),parseExpr());
            } else {
              return makeifgt0(parseExpr(),parseExpr(),parseExpr());
            }
          }
        }
      }
    }
  }
}

// given an expression, print it to stdout
// in the same format read by parseExpr
int writeExpr(struct Expr *l) {
  int dc;
  printint(l->kind);
  if ((l->kind == 0)||(l->kind == 1)) {
    printint(l->num);
    return 0;
  } else {
    if ((l->kind == 2)||(l->kind == 4)||(l->kind==5)) {
      dc = writeExpr(l->a1);
      dc = writeExpr(l->a2);
      return 0;
    } else {
      if (l->kind == 3) {
        printint(l->num);
        dc = writeExpr(l->a1);
        return 0;
      } else {
        dc = writeExpr(l->a1);
        dc = writeExpr(l->a2);
        dc = writeExpr(l->a3);
        return 0;
      }      
    }
  }
}



// interpret an expression:
struct Expr * interp(struct Expr *l) {
  int dc;
  // numbers and lambdas are values:
  if ((l->kind == 0)||(l->kind == 3)) {
    return l;
  } else {
    // a naked varref is an error:
    if (l->kind == 1) {
      dc = 1 / 0;
      // bogus return value:
      return l;
    } else {
      // plus
      if (l->kind == 4) {
        return add(interp(l->a1),interp(l->a2));
      } else {
        if (l->kind == 5) {
          return subtract(interp(l->a1),interp(l->a2));  
        } else {
          if (l->kind == 6) {
             return iftest(interp(l->a1),l->a2,l->a3);
          } else {
            // must be an application
            return app(interp(l->a1),interp(l->a2));
          }
        }
      }
    }
  }
}

// go go go!
int main() {
  int dc;
  dc = writeExpr(interp(parseExpr()));
  printintln(-1);
  return 0;
}
